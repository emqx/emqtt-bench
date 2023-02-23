ARG FROM=ghcr.io/emqx/emqx-builder/5.0-29:1.13.4-24.3.4.2-2-debian11
FROM ${FROM}
COPY . /emqtt_bench
WORKDIR /emqtt_bench
RUN make compile
ENTRYPOINT ["./emqtt_bench"]
CMD [""]
