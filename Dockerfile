ARG FROM=ghcr.io/emqx/emqx-builder/5.5-2:1.18.3-27.2-3-debian12
FROM ${FROM} AS builder
COPY . /emqtt_bench
WORKDIR /emqtt_bench
ENV BUILD_WITHOUT_QUIC=1
RUN make release

FROM debian:12-slim

COPY --from=builder /emqtt_bench/emqtt-bench-*.tar.gz /emqtt_bench/

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates procps curl; \
    rm -rf /var/lib/apt/lists/*; \
    groupadd -r -g 1000 emqtt_bench; \
    useradd -r -m -u 1000 -g emqtt_bench emqtt_bench; \
    cd /emqtt_bench && \
    tar zxf emqtt-bench-*.tar.gz && \
    rm emqtt-bench-*.tar.gz && \
    chown -R emqtt_bench:emqtt_bench /emqtt_bench

ENTRYPOINT ["/emqtt_bench/bin/emqtt_bench"]
CMD [""]
