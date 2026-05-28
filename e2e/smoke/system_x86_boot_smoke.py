import json
import os
import subprocess
import sys
import tempfile

from python.runfiles import runfiles

BOOT_MARKER = "BOOT_OK"

_RUNFILES = runfiles.Create()


def rlocation(path):
    resolved = _RUNFILES.Rlocation(path)
    if resolved:
        return resolved
    if os.path.exists(path):
        return path
    raise FileNotFoundError(path)


def load_config(path):
    with open(rlocation(path), "r", encoding="utf-8") as config_file:
        return json.load(config_file)


class BootSectorBuilder:
    def __init__(self):
        self.code = bytearray()
        self.labels = {}
        self.fixups = []

    def label(self, name):
        self.labels[name] = len(self.code)

    def emit(self, *values):
        self.code.extend(values)

    def emit_bytes(self, values):
        self.code.extend(values)

    def mov_dx(self, value):
        self.emit(0xBA, value & 0xFF, value >> 8)

    def mov_al(self, value):
        self.emit(0xB0, value)

    def mov_si_label(self, label):
        self.emit(0xBE, 0x00, 0x00)
        self.fixups.append(("abs16", len(self.code) - 2, label))

    def jz(self, label):
        self.emit(0x74, 0x00)
        self.fixups.append(("rel8", len(self.code) - 1, label))

    def jmp(self, label):
        self.emit(0xEB, 0x00)
        self.fixups.append(("rel8", len(self.code) - 1, label))

    def call(self, label):
        self.emit(0xE8, 0x00, 0x00)
        self.fixups.append(("rel16", len(self.code) - 2, label))

    def resolve(self):
        base = 0x7C00
        for kind, offset, label in self.fixups:
            target = self.labels[label]
            if kind == "abs16":
                value = base + target
                self.code[offset] = value & 0xFF
                self.code[offset + 1] = value >> 8
            elif kind == "rel8":
                value = target - (offset + 1)
                if value < -128 or value > 127:
                    raise ValueError("rel8 fixup out of range for {}".format(label))
                self.code[offset] = value & 0xFF
            elif kind == "rel16":
                value = target - (offset + 2)
                if value < -32768 or value > 32767:
                    raise ValueError("rel16 fixup out of range for {}".format(label))
                self.code[offset] = value & 0xFF
                self.code[offset + 1] = (value >> 8) & 0xFF
            else:
                raise ValueError("unknown fixup kind {}".format(kind))


def build_boot_sector():
    asm = BootSectorBuilder()

    asm.emit(0xFA)  # cli
    asm.emit(0x31, 0xC0)  # xor ax, ax
    asm.emit(0x8E, 0xD8)  # mov ds, ax
    asm.emit(0x8E, 0xD0)  # mov ss, ax
    asm.emit(0xBC, 0x00, 0x7C)  # mov sp, 0x7c00
    asm.emit(0xFB)  # sti

    asm.mov_dx(0x03F9)
    asm.emit(0x30, 0xC0)  # xor al, al
    asm.emit(0xEE)  # out dx, al
    asm.mov_dx(0x03FB)
    asm.mov_al(0x80)
    asm.emit(0xEE)
    asm.mov_dx(0x03F8)
    asm.mov_al(0x03)
    asm.emit(0xEE)
    asm.mov_dx(0x03F9)
    asm.emit(0x30, 0xC0)
    asm.emit(0xEE)
    asm.mov_dx(0x03FB)
    asm.mov_al(0x03)
    asm.emit(0xEE)
    asm.mov_dx(0x03FA)
    asm.mov_al(0xC7)
    asm.emit(0xEE)
    asm.mov_dx(0x03FC)
    asm.mov_al(0x0B)
    asm.emit(0xEE)

    asm.mov_si_label("message")
    asm.label("print")
    asm.emit(0xAC)  # lodsb
    asm.emit(0x84, 0xC0)  # test al, al
    asm.jz("exit")
    asm.call("putc")
    asm.jmp("print")

    asm.label("putc")
    asm.emit(0x50)  # push ax
    asm.label("wait_tx")
    asm.mov_dx(0x03FD)
    asm.emit(0xEC)  # in al, dx
    asm.emit(0xA8, 0x20)  # test al, 0x20
    asm.jz("wait_tx")
    asm.emit(0x58)  # pop ax
    asm.mov_dx(0x03F8)
    asm.emit(0xEE)  # out dx, al
    asm.emit(0xC3)  # ret

    asm.label("exit")
    asm.mov_dx(0x00F4)
    asm.mov_al(0x21)
    asm.emit(0xEE)  # out dx, al
    asm.label("halt")
    asm.emit(0xF4)  # hlt
    asm.jmp("halt")

    asm.label("message")
    asm.emit_bytes(BOOT_MARKER.encode("ascii") + b"\n\x00")
    asm.resolve()

    if len(asm.code) > 510:
        raise ValueError("boot sector is too large")

    return bytes(asm.code) + bytes(510 - len(asm.code)) + b"\x55\xAA"


def main():
    config = load_config(sys.argv[1])
    if config["system_target"] != "x86_64-softmmu":
        raise RuntimeError("x86 boot smoke requires x86_64-softmmu, got {}".format(config["system_target"]))

    qemu_system = rlocation(config["qemu_system"])
    system_data_dir = rlocation(config["system_data_anchor"])

    tmpdir = os.environ.get("TEST_TMPDIR") or tempfile.mkdtemp(prefix="qemu-system-boot-")
    image = os.path.join(tmpdir, "boot.img")
    with open(image, "wb") as image_file:
        image_file.write(build_boot_sector())
        image_file.truncate(1024 * 1024)

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
        "-monitor",
        "none",
        "-serial",
        "stdio",
        "-no-reboot",
        "-device",
        "isa-debug-exit,iobase=0xf4,iosize=0x01",
        "-drive",
        "file={},format=raw,if=virtio".format(image),
        "-boot",
        "c",
    ]
    proc = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    try:
        stdout, stderr = proc.communicate(timeout=20)
    except subprocess.TimeoutExpired:
        proc.kill()
        stdout, stderr = proc.communicate()
        sys.stderr.write(stdout)
        sys.stderr.write(stderr)
        raise RuntimeError("qemu-system did not exit after boot timeout")

    if BOOT_MARKER not in stdout:
        sys.stderr.write(stdout)
        sys.stderr.write(stderr)
        raise RuntimeError("boot marker was not written to serial output")

    if proc.returncode != 67:
        sys.stderr.write(stdout)
        sys.stderr.write(stderr)
        raise RuntimeError("unexpected qemu-system exit code {}".format(proc.returncode))


if __name__ == "__main__":
    main()
