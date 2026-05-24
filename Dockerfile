FROM ubuntu:24.04

# MuseScore docker image, running the AppImage on top of Ubuntu 24.04.
# By: melodysium
# Find the correct AppImage download link here: https://github.com/musescore/MuseScore/tags

# Build args can be directly overridden at build time i.e. `--build-arg MUSESCORE_DL_LINK=https://...` in `docker build` command
# Load args about target architecture
ARG TARGETARCH TARGETPLATFORM TARGETOS
# MuseScore version
ARG MUSESCORE_VERSION=4.7.1
LABEL musescore.version=${MUSESCORE_VERSION}
# Build date for the specified MuseScore version, taken from the GitHub release page
# TODO: inject this via build script querying GitHub releases API: https://api.github.com/repos/musescore/MuseScore/releases/tags/v${MUSESCORE_VERSION}
ARG MUSESCORE_VERSION_DATE=260518142
# Musescore AppImage download link
ARG MUSESCORE_DL_LINK=https://github.com/musescore/MuseScore/releases/download/v${MUSESCORE_VERSION}/MuseScore-Studio-${MUSESCORE_VERSION}.${MUSESCORE_VERSION_DATE}-\${ARCH}.AppImage
# Shadow arg of same name to make it available within image
ENV MUSESCORE_DL_LINK=${MUSESCORE_DL_LINK}
RUN echo "TARGETARCH=${TARGETARCH} TARGETPLATFORM=${TARGETPLATFORM} TARGETOS=${TARGETOS}"
RUN echo "${MUSESCORE_DL_LINK}"

# Musescore Shared-Object package dependencies for running in the target environment
ARG MUSESCORE_SO_DEPS="libopengl0 libasound2t64 libgl1 libegl1 libfontconfig1 libglib2.0-0t64 libharfbuzz0b libpipewire-0.3-0t64"
ENV MUSESCORE_SO_DEPS=${MUSESCORE_SO_DEPS}

# install into opt directory
WORKDIR /opt

# Run a bunch of shell commands in a row, so that we minimize layer size by only saving a new layer after we clean up from a sizeable install process
RUN <<EOF
set -e
# apt-get update && apt-get install: Install necessary dependencies
#   - gettext-base: necessary for envsubst below
#   - wget, ca-certificates: web download utility and certificates for trusting external websites. only used for downloading AppImage, then removed
#   - libopengl0 ...: general libraries necessary for MuseScore to function
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-suggests gettext-base wget ca-certificates ${MUSESCORE_SO_DEPS}

# determine exact MuseScore download link based on image architecture
case ${TARGETARCH} in
    amd64) export ARCH="x86_64" ;;
    arm64) export ARCH="aarch64" ;;
    *) echo "Unsupported arch: ${TARGETARCH}" && exit 1 ;;
esac
export MUSESCORE_DL_LINK=$(echo "$MUSESCORE_DL_LINK" | envsubst)
echo "$MUSESCORE_DL_LINK"

# download MuseScore AppImage and make it executable
wget -qO musescore.appimage ${MUSESCORE_DL_LINK}
chmod +x musescore.appimage

# uncomment these lines to save a build cache entry before running the MuseScore AppImage
# EOF
# RUN <<EOF
# set -e

# run the AppImage to extract it, placing contents in /opt/squashfs-root
./musescore.appimage --appimage-extract

# clean up unnecessary leftovers
apt-get remove -y wget ca-certificates gettext-base
rm musescore.appimage
EOF

# Add install directory to path
# TODO: instead, put a shim script which always uses `-platform offscreen`
ENV PATH="$PATH:/opt/squashfs-root/bin"

# Set application to run in headless mode. This doesn't actually seem to be respected since cmdline arg `-platform` is necessary, but whatever, I'll still set it, you can't stop me.
ENV QT_QPA_PLATFORM="offscreen"

# Set locale correctly to hide warnings from Qt
ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

# Verify running musescore CLI works
RUN set -e && mscore4portable -platform offscreen --help

# Run mscore4portable CLI. Requires arguments `-platform offscreen` to run in headless mode.
ENTRYPOINT [ "mscore4portable", "-platform", "offscreen" ]
