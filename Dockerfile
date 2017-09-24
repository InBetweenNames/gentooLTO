#FROM gentoo/portage:latest AS portage
FROM chinstrap/overlay-docker:latest

#COPY --from=portage /usr/portage /usr/portage

RUN emerge-webrsync -q && emerge --sync --quiet
RUN /bin/bash /build.sh -v -d -o lto-overlay -u 
https://raw.githubusercontent.com/InBetweenNames/gentooLTO/master/repositories.xml -p lto-overlay:lto-overlay/default/linux/amd64/13.0
