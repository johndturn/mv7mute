---
description: Run the definition-of-done checks (fmt, clippy, tests, locked build, privacy scan)
---

Run the definition of done from AGENTS.md and report a pass/fail table. Do not run the binary against the mic.

```bash
cargo fmt -p mv7mute-core -p mv7mute -- --check
cargo clippy --workspace --all-targets --locked -- -D warnings
cargo test --workspace --locked
cargo build --release --locked -p mv7mute
scripts/privacy-scan.sh --staged && scripts/privacy-scan.sh --outgoing
command -v cargo-audit >/dev/null && cargo audit || echo "cargo-audit not installed"
git status --short
```

If anything fails, show the relevant output and propose the fix; don't apply it unless I ask. For a large change,
delegate to the `verifier` subagent instead so the logs stay out of this context.
