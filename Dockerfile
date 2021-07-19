FROM emqx/build-env:erl23.2.7.2-emqx-2-alpine-amd64
COPY . /emqtt_bench
WORKDIR /emqtt_bench
RUN make
ENTRYPOINT ["./emqtt_bench"]
CMD [""]
