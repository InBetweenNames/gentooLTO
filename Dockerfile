#FROM gentoo/portage:latest AS portage
FROM chinstrap/overlay-docker:latest

#COPY --from=portage /usr/portage /usr/portage

RUN emerge-webrsync && emerge --sync
RUN /bin/bash /build.sh -v -d -o lto-overlay -u https://raw.githubusercontent.com/mgomersbach/gentooLTO/fleshen-out-profiles/repositories.xml -p lto-overlay:lto-overlay/default/linux/amd64
