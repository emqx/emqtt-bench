ARG FROM=ghcr.io/emqx/emqx-builder/5.0-16:1.13.4-24.2.1-1-alpine3.15.1
FROM ${FROM}
COPY . /emqtt_bench
WORKDIR /emqtt_bench
RUN make compile
ENTRYPOINT ["./emqtt_bench"]
CMD [""]
