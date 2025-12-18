# Development Guide

This repository builds the final agent images. Use it when you need to change agent installers,
adjust Dockerfiles, or update smoke tests.

## Prerequisites

- Docker (`docker --version`).
- QEMU/binfmt for multi-arch builds (often installed with Docker Desktop).
- Bats (`bats --version`) for smoke suites.
- yq (`yq --version`) for parsing config and tool metadata.
- Python 3.11+ with `pip install -r requirements-dev.txt` to pull lint/test tooling (e.g., ruff,
  pymarkdown).

## Setup

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
```

## Repo layout

- `Dockerfile` — Build entrypoint for agent images.
- `tools/<tool>/install.sh` — Installer for each agent.
- `tools/<tool>/tool.yaml` — Key/value metadata labels baked into the image.
- `scripts/` — Build and test helpers.
- `tests/smoke/` — Bats suites that verify each tool’s image.
- `config.yaml` — Default repositories, platforms, and version tags.

## Key configuration

`config.yaml` controls defaults:

- `AICAGE_REPOSITORY` (default `wuodan/aicage`)
- `AICAGE_IMAGE_BASE_REPOSITORY` (default `wuodan/aicage-image-base`)
- `AICAGE_VERSION` (default `dev`)
- `AICAGE_PLATFORMS` (default `linux/amd64 linux/arm64`)
Base aliases are discovered from `<alias>-latest` tags in the base repository unless you override
`AICAGE_BASE_ALIASES`.

## Build

```bash
# Build and load a single agent image (host architecture)
scripts/util/build.sh --tool codex --base ubuntu

# Build the full tool/base matrix (tags derived from config.yaml)
scripts/util/build-all.sh
```

## Test

```bash
# Test a specific image
scripts/test.sh --image wuodan/aicage:codex-ubuntu-latest --tool codex

# Test the full matrix (tags derived from config.yaml and available base aliases)
scripts/test-all.sh
```

Smoke suites live in `tests/smoke/`; use `bats` directly if you need to run one file.

## Adding a tool

1. Create `tools/<tool>/install.sh` (executable) that installs the agent; fail fast on errors.
2. Add `tools/<tool>/tool.yaml` with any metadata that should appear as image labels.
3. Add the tool to `AICAGE_TOOLS` in `config.yaml` if it isn’t discovered automatically.
4. Add smoke coverage in `tests/smoke/<tool>.bats`.
5. Document the tool in `README.md` if it should be visible to users.

## Working with bases

Base layers come from `wuodan/aicage-image-base`. Add or modify bases in that repository, then ensure
the desired `<base>-latest` tag exists (or set `AICAGE_BASE_ALIASES`) before building here.

## CI

Workflows under `.github/workflows/` dispatch per-tool (`build-tool.yml`) and per-base
(`build.yml`) builds on tag pushes and on schedule. Each pipeline builds and tests native
`amd64`/`arm64` images on matching runners, then publishes a multi-arch manifest.
