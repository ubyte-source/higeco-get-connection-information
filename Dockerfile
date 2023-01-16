FROM amd64/debian:stable-slim

ENV TOOL="/tool"

COPY ./wrapper.sh /wrapper.sh
COPY ./tool ${TOOL}

RUN apt update && apt install -y curl ca-certificates bash wget jq default-mysql-client ipcalc sshpass grepcidr procps && \
    chmod +x -R ${TOOL} && \
    chmod +x /wrapper.sh

ENTRYPOINT /wrapper.sh
