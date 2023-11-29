ARG FROM=ghcr.io/emqx/emqx-builder/5.2-7:1.15.7-25.3.2-2-debian11
FROM ${FROM}
COPY . /emqtt_bench
WORKDIR /emqtt_bench
RUN make compile
ENTRYPOINT ["/emqtt_bench/emqtt_bench"]
CMD [""]
