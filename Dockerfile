# All this image is meant to do is act as a build environment with all of the
# needed libraries, nothing more. Anything that isn't building the basic image
# is beyond this.
FROM ubuntu:jammy

RUN dpkg --add-architecture i386
RUN apt-get update

# Install make and hexdump tools
RUN apt-get -y install build-essential bsdextrautils

# Install multi-arch libs
RUN apt-get -y install libc6-dev-i386 libc6-i386 libc6-x32
RUN apt-get -y install zlib1g:i386 libstdc++6:i386


# Create and move to the src volume. This lets the container just pull in the
# the source and compile it, while also leaving files behind after it's done
VOLUME ["/src"]
WORKDIR /src

CMD [ "make" ]
RUN chmod -R jarchi .
