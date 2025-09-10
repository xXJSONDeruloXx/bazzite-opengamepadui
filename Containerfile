# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image - Use bazzite-deck for handheld gaming optimizations
FROM ghcr.io/ublue-os/bazzite-deck:stable

## This image is based on Bazzite-deck which provides:
# - Steam Deck and handheld gaming device optimizations
# - Gamescope compositor for gaming
# - Hardware-specific drivers and configurations
# - Gaming-focused kernel parameters and system settings

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint