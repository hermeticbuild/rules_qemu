import json
import os
import socket
import subprocess
import sys
import tempfile
import time


def rlocation(path):
    runfiles_dir = os.environ.get("RUNFILES_DIR")
    if runfiles_dir:
        candidate = os.path.join(runfiles_dir, path)
        if os.path.exists(candidate):
            return candidate

    manifest = os.environ.get("RUNFILES_MANIFEST_FILE")
    if manifest:
        with open(manifest, "r", encoding="utf-8") as manifest_file:
            for line in manifest_file:
                key, _, value = line.rstrip("\n").partition(" ")
                if key == path:
                    return value

    if os.path.exists(path):
        return path

    raise FileNotFoundError(path)


def run_checked(args):
    try:
        return subprocess.run(
            args,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        sys.stderr.write(exc.stdout)
        sys.stderr.write(exc.stderr)
        raise


def qmp_recv(reader):
    line = reader.readline()
    if not line:
        raise RuntimeError("QMP socket closed before response")
    return json.loads(line.decode("utf-8"))


def qmp_send(sock, command):
    sock.sendall(json.dumps(command).encode("utf-8") + b"\r\n")


def allocate_tcp_port():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
        listener.bind(("127.0.0.1", 0))
        return listener.getsockname()[1]


def connect_qmp(port):
    deadline = time.time() + 10
    last_error = None
    while time.time() < deadline:
        try:
            client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            client.connect(("127.0.0.1", port))
            return client
        except OSError as exc:
            last_error = exc
            time.sleep(0.05)
    raise TimeoutError("timed out connecting to QMP port {}: {}".format(port, last_error))


def load_config(path):
    with open(rlocation(path), "r", encoding="utf-8") as config_file:
        return json.load(config_file)


def main():
    config = load_config(sys.argv[1])
    qemu_system = rlocation(config["qemu_system"])
    qemu_img = rlocation(config["qemu_img"])
    system_data_dir = rlocation(config["system_data_anchor"])

    tmpdir = os.environ.get("TEST_TMPDIR") or tempfile.mkdtemp(prefix="qemu-system-smoke-")
    image = os.path.join(tmpdir, "disk.qcow2")
    qmp_port = allocate_tcp_port()

    run_checked([qemu_img, "create", "-f", "qcow2", image, "1M"])
    image_info = run_checked([qemu_img, "info", "--output=json", image])
    if json.loads(image_info.stdout).get("format") != "qcow2":
        raise RuntimeError("qemu-img did not create a qcow2 image")

    command = [
        qemu_system,
        "-L",
        system_data_dir,
        "-machine",
        config["machine"],
        "-accel",
        config["accel"],
        "-nodefaults",
        "-display",
        "none",
        "-serial",
        "none",
        "-S",
        "-qmp",
        "tcp:127.0.0.1:{},server=on,wait=off".format(qmp_port),
    ]
    proc = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    try:
        client = connect_qmp(qmp_port)
        with client:
            reader = client.makefile("rb")
            greeting = qmp_recv(reader)
            if "QMP" not in greeting:
                raise RuntimeError("missing QMP greeting: {!r}".format(greeting))

            qmp_send(client, {"execute": "qmp_capabilities"})
            capabilities = qmp_recv(reader)
            if "return" not in capabilities:
                raise RuntimeError("qmp_capabilities failed: {!r}".format(capabilities))

            qmp_send(client, {"execute": "query-status"})
            status = qmp_recv(reader)
            if "return" not in status or "status" not in status["return"]:
                raise RuntimeError("query-status failed: {!r}".format(status))

            qmp_send(client, {"execute": "quit"})
        proc.wait(timeout=10)
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=5)

    if proc.returncode not in (0, None):
        stdout, stderr = proc.communicate()
        sys.stderr.write(stdout)
        sys.stderr.write(stderr)
        raise RuntimeError("qemu-system exited with {}".format(proc.returncode))


if __name__ == "__main__":
    main()
