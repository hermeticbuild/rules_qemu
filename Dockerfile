FROM ubuntu:24.04

ARG BAZELISK_VERSION=1.18.0
ARG BAZEL_VERSION=9.1.0
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
ENV USE_BAZEL_VERSION=${BAZEL_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL \
    "https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-${TARGETARCH}" \
    -o /usr/bin/bazel \
    && chmod +x /usr/bin/bazel

RUN useradd --create-home --shell /bin/bash fakeuser
USER fakeuser

WORKDIR /rules_qemu
RUN cd /tmp && bazel help >/dev/null

CMD ["bash"]
