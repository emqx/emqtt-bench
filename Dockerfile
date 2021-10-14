ARG FROM=ghcr.io/emqx/emqx-builder-helper/5.0:24.0.5-emqx-1-alpine3.14
FROM ${FROM}
COPY . /emqtt_bench
WORKDIR /emqtt_bench
RUN make compile
ENTRYPOINT ["./emqtt_bench"]
CMD [""]
