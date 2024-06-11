ARG FROM=ghcr.io/emqx/emqx-builder/5.3-7:1.15.7-26.2.5-1-debian12
FROM ${FROM}
COPY . /emqtt_bench
WORKDIR /emqtt_bench
RUN make compile
ENTRYPOINT ["/emqtt_bench/emqtt_bench"]
CMD [""]
