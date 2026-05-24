# musescore-docker

Docker image for running MuseScore headless CLI

## How to use

Image is pushed to DockerHub at: 

## Build

Override either `MUSESCORE_DL_LINK` or multiple preceding args with `--build-arg=<value>` in your `docker build` command.

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
