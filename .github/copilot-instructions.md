## AI agent guide for this repo (image-template)

Purpose: make AI agents productive in this bootc-based image template. Keep changes small, declarative, idempotent.

Overview
- Builds a bootc OS as an OCI container, published to GHCR; optionally emits ISO/qcow2/raw via Bootc Image Builder (BIB).
- Key files: `Containerfile` (base + layers), `build_files/build.sh` (packages/tweaks), `Justfile` (local build/run), `disk_config/*.toml` (BIB settings), `artifacthub-repo.yml` (listing).
- CI workflows: `.github/workflows/build.yml` (builds/signs/pushes to GHCR) and `.github/workflows/build-disk.yml` (creates ISO/qcow2/raw using BIB).

Prereqs and host assumptions
- Run on a bootc-based host (Bazzite/Bluefin/Aurora/Fedora Atomic). Verify with: sudo bootc status.
- GHCR access and GitHub Actions enabled if you plan to publish via CI.

Signing (required for CI)
1) Generate keys (no password) in repo root: COSIGN_PASSWORD="" cosign generate-key-pair. Do NOT commit `cosign.key` (commit only `cosign.pub`).
2) Add `SIGNING_SECRET` Actions secret containing the private key.

Core developer loop
- Pick base: edit `FROM` (e.g., `ghcr.io/ublue-os/bazzite:stable` or `quay.io/fedora/fedora-bootc:<ver>`).
- Customize in `build_files/build.sh` using `dnf5` and `systemctl enable ...`; don’t start services during build.
- Local build: just build <image_name> <tag> (defaults from `Justfile`: `image_name`, `default_tag`).
- Switch a host: sudo bootc switch ghcr.io/<user>/<image>:<tag> → reboot; confirm with sudo bootc status.
- Update: commit/publish, then sudo bootc update → reboot. Rollback: sudo bootc rollback → reboot.

Local workflows (Just)
- Disk images (output under `./output/`): `just build-qcow2`, `just build-raw`, `just build-iso`.
- Run VM (web UI on available localhost port, starting at 8006): `just run-vm-qcow2` or `just run-vm-iso`.
- Hygiene: `just clean`, `just lint` (shellcheck), `just format` (shfmt), `just check`/`just fix` (Justfile).

Conventions and patterns
- `Containerfile` uses `RUN --mount` and a scratch `ctx` stage to bind-mount `build_files/`; do not copy those files into the final image.
- Rootful vs rootless podman is handled by `_rootful_load_image` in `Justfile`; prefer calling the provided recipes.
- Tags and names: override `IMAGE_NAME`/`DEFAULT_TAG` envs or edit `Justfile`.
- Disk configs: update `disk_config/disk.toml` and `disk_config/iso-*.toml` (e.g., `iso-gnome.toml`, `iso-kde.toml`). Ensure `%post` kickstart references your image, e.g., `ghcr.io/<user>/<image>:<tag>`.

External deps
- Podman, Just, jq, shellcheck, shfmt; `BIB_IMAGE` env selects the BIB container (default: quay.io/centos-bootc/bootc-image-builder:latest). VM runner uses `docker.io/qemux/qemu` and `/dev/kvm`.

Tips
- Validate package names in a Fedora Toolbox before editing `build.sh` (toolbox create → toolbox enter → sudo dnf install <pkg>), to avoid CI churn.

Gotchas
- Mismatched image refs in `disk_config/*` prevent installed systems from switching to your image.
- Don’t run services at build time; enabling units is enough for bootc.
- If `run-vm-*` doesn’t open a browser, use the printed localhost port.

CI workflows in this template (GHCR paths are user-specific)
- `.github/workflows/build.yml` publishes to GHCR. Images default to `ghcr.io/<owner>/<repo>:<tag>` (image name typically matches repo). Adjust env like `IMAGE_NAME`, `DEFAULT_TAG`, and (if present) `IMAGE_REGISTRY` to match your desired GHCR namespace.
- `.github/workflows/build-disk.yml` converts your container to installable media. Ensure `disk_config/iso-*.toml` kickstart `%post` uses your image ref, e.g., `ghcr.io/<owner>/<repo>:latest`.
- After CI push, switch hosts with: `sudo bootc switch ghcr.io/<owner>/<repo>:<tag>` → reboot; later updates via `sudo bootc update` → reboot; rollback with `sudo bootc rollback`.
