FROM ghcr.io/emqx/emqx-builder-helper/5.0:23.2.7.2-emqx-2-alpine3.14
COPY . /emqtt_bench
WORKDIR /emqtt_bench
RUN make compile
ENTRYPOINT ["./emqtt_bench"]
CMD [""]
