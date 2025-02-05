# emqtt-bench changelog

## 0.4.32

* QoE: Fix csv dump, represent `invalid_elapsed` as `""` instead of `-1`
* TLS: support `--ciphers` and `--signature-algs`

## 0.4.31

* New `--ssl-version` to enforce TLS version and implies ssl is enabled.
* QoE logging now logs TCP handshake latency during TLS handshake ( emqtt 1.14.0).
* QoE logging now logs each publish msg' end to end latency if `--payload-hdrs=ts` is set by both subscriber and publisher. 
* Dump TLS secrets per connecion to SSLKEYLOGFILE specifed by envvar SSLKEYLOGFILE for TLS traffic decryption.  (TLS and QUIC)
* Now build release for arm64.
* Now build release for el7 with newer build image.

## 0.4.30

* Enhanced QoE trackings, add supports for commands `conn` and `pub`.
* Write QoE event logs to disklog for post processing with `--qoe true --qoelog logfile`
* Dump QoE disklog to csv file with combined opts `--qoe dump --qoelog logfile`
  
## 0.4.29

* Fix OOM issue.

## 0.4.28

* release: fix and re-enable no-quic build

## 0.4.27

* Add bench `cacertfile` option for completeness.

## 0.4.26

* Upgrade emqtt to 1.13.4 so initial CONNECT packet send failures will not cause client to shutdown/crash.

## 0.4.13

* Add `--retry-interval` option to `pub` command and use `0` as default value (0 means disable resend).

## 0.4.5

* Default value for `--inflight` option is changed from `0` (no back-pressure) to `1`.
  i.e. `max-inflight` is `1` by default for QoS 1 and 2 messages.

## 0.4.4

Main changes comparing to 0.4.0

* Release on otp 24.2.1
* Multiple source IP address support (to get around the 64K source port limit)
* Reports publisher overrun for QoS 1 (when the ack is received after the interval set by `--interval_of_msg` option)

## 0.4 (2019-07-29)

Use the new Erlang MQTT v5.0 client

## 0.3 (2016-01-29)

emqtt_bench_sub: support to subscribe multiple topics (#9)

## 0.2 (2015-10-08)

emqtt_bench_pub, emqtt_bench_sub scripts

## 0.1 (2015-04-23)

first public release

