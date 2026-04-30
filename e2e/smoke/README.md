# Smoke Test

This module tests `rules_qemu` as an external Bzlmod consumer. It uses the
published `llvm` module rather than a local checkout so it matches CI, remote
execution, and release behavior.
