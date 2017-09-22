FROM gentoo/portage:latest AS portage
FROM chinstrap/overlay-docker AS stage3

COPY --from=portage /usr/portage /usr/portage

RUN /bin/bash /build.sh -v -d -o lto-overlay -u https://raw.githubusercontent.com/mgomersbach/gentooLTO/fleshen-out-profiles/repositories.xml -p lto-overlay:lto-overlay/default/linux/amd64
