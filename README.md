# musescore-docker

Docker image for running MuseScore headless CLI

## How to use

Image is pushed to DockerHub at: <https://hub.docker.com/repository/docker/melodysium/musescore>

## Build

Override either `MUSESCORE_DL_LINK` or multiple preceding args with `--build-arg=<value>` in your `docker build` command.
If you set the DL_LINK directly, be careful to pick the right architecture.

## Troubleshooting

### Missing Shared Libraries

If you change the MuseScore version and find you get an error message like:

```sh
squashfs-root/bin/mscore4portable: error while loading shared libraries: libpipewire-0.3.so.0: cannot open shared object file: No such file or directory
```

Then:

1.  Run the image with a shell entrypoint: `docker run -it --entrypoint=/bin/bash <image-name>`
1.  Identify any shared libraries required for this musescore version but not present: `ldd squashfs-root/bin/mscore4portable | grep "not found"`.
    -   Grab all shared library names, like "libpipewire-0.3.so.0".
1.  Search `<lib name> ubuntu 24.04` online to find the necessary package(s)
1.  Run `apt install -y <package-names...>` in the container.
1.  Run `squashfs-root/bin/mscore4portable -platform offscreen --help` to verify the fix. If it doesn't fix it, go back and troubleshoot.
1.  Add the necessary package(s) to the `MUSESCORE_SO_DEPS` argument and re-build

### Cross-architecture build on MacOs

I ran into difficulties building an `amd64` image on Mac M1 with Rosetta emulation.
When running the `--appimage-extract` step, I would get `/bin/sh: 28: ./musescore.appimage: Exec format error`.
I was able to get around this by using Colima with QEMU VM instead of Rosatta (at the cost of high build times).

Try this setup if you're having similar issues:

```sh
colima start intel --arch amd64 --vm-type qemu
docker build --platform linux/amd64 .
```
