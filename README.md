# Lightweight MQTT Benchmark Tool written in Erlang

![image](https://user-images.githubusercontent.com/164324/191903878-7f675d84-e38f-4aaf-81fa-c691d9ceb28b.png)


`eMQTT-Bench` is a lightweight MQTT v5.0 benchmark tool written in Erlang.

You can download pre-built binary packeges from https://github.com/emqx/emqtt-bench/releases.

## Build from source code

NOTE: Requires **Erlang/OTP 22.3+** to build.

### Install dependencies

emqtt-bench requires `libatomic`

``` sh
# centos 7
sudo yum install libatomic
```

``` sh
# ubuntu 20.04
sudo apt install libatomic1
```

### make

```sh
git clone https://github.com/emqx/emqtt-bench.git
cd emqtt-bench
make
```

Optional, you could disable QUIC support if you have problem with compiling
``` sh
BUILD_WITHOUT_QUIC=1 make
```

## Connect Benchmark

``` sh
Usage: emqtt_bench conn [--help <help>] [-d <dist>] [-h [<host>]] [-p [<port>]] [-V [<version>]] [-c [<count>]]
                        [-R [<conn_rate>]] [-i [<interval>]] [--ifaddr <ifaddr>] [--prefix <prefix>] [-s [<shortids>]]
                        [-n [<startnumber>]] [--num-retry-connect [<num_retry_connect>]] [-R [<conn_rate>]]
                        [--reconnect [<reconnect>]] [-S [<ssl>]] [--ssl-version <sslversion>] [--cacertfile <cacertfile>]
                        [--certfile <certfile>] [--keyfile <keyfile>] [--ciphers <ciphers>]
                        [--signature-algs <signature_algs>] [--keyex-algs <keyex_algs>] [--quic [<quic>]] [--ws [<ws>]]
                        [--load-qst <nst_dets_file>] [-u <username>] [-P <password>] [-k [<keepalive>]] [-C [<clean>]]
                        [-x [<expiry>]] [-l <lowmem>] [--force-major-gc-interval [<force_major_gc_interval>]] [-Q [<qoe>]]
                        [--qoelog [<qoelog>]] [--prometheus] [--restapi [<restapi>]] [--log_to [<log_to>]]

  --help                     help information
  -d, --dist                 enable distribution port
  -h, --host                 mqtt server hostname or comma-separated hostnames [default: localhost]
  -p, --port                 mqtt server port number [default: 1883]
  -V, --version              mqtt protocol version: 3 | 4 | 5 [default: 5]
  -c, --count                max count of clients [default: 200]
  -R, --connrate             connection rate(/s), default: 0, fallback to use --interval [default: 0]
  -i, --interval             interval of connecting to the broker [default: 10]
  --ifaddr                   local ipaddress or interface address
  --prefix                   Client ID prefix. If not provided '$HOST_bench_(pub|sub)_$RANDOM_$N' is used, where $HOST is 
                             either the host name or the IP address provided in the --ifaddr option, $RANDOM is a random 
                             number and $N is the sequence number assigned for each client. If provided, the $RANDOM suffix 
                             will not be added.
  -s, --shortids             Use short client ID. If --prefix is provided, the prefix is added otherwise client ID is the 
                             assigned sequence number. [default: false]
  -n, --startnumber          The start point when assigning sequence numbers to clients. This is useful when running 
                             multiple emqtt-bench instances to test the same broker (cluster), so the start number can be 
                             planned to avoid client ID collision [default: 0]
  --num-retry-connect        number of times to retry estabilishing a connection before giving up [default: 0]
  --reconnect                max retries of reconnects. 0: disabled [default: 0]
  -S, --ssl                  ssl socket for connecting to server [default: false]
  --ssl-version              enforce tls version and implies ssl is enabled, 'tlsv1.1' | 'tlsv1.2' | 'tlsv1.3' | 
                             'tlsv1.3_nocompat'
  --cacertfile               CA certificate for server verification
  --certfile                 client certificate for authentication, if required by server
  --keyfile                  client private key for authentication, if required by server
  --ciphers                  Cipher suite for ssl/tls connection, comma separated list. e.g. 
                             TLS_AES_256_GCM_SHA384,TLS_CHACHA20_POLY1305_SHA256
  --signature-algs           Signature algorithm for tlsv1.3 connection only, comma separated list. e.g. 
                             ecdsa_secp384r1_sha384,ecdsa_secp256r1_sha256
  --keyex-algs               Key exchange algorithm for tlsv1.3 connection only, comma separated list. e.g. 
                             secp384r1,secp256r1
  --quic                     QUIC transport [default: false]
  --ws                       websocket transport [default: false]
  --load-qst                 load quic session tickets from dets file
  -u, --username             username for connecting to server
  -P, --password             password for connecting to server
  -k, --keepalive            keep alive in seconds [default: 300]
  -C, --clean                clean session [default: true]
  -x, --session-expiry       Set 'Session-Expiry' for persistent sessions (seconds) [default: 0]
  -l, --lowmem               enable low mem mode, but use more CPU
  --force-major-gc-interval  interval in milliseconds in which a major GC will be forced on the bench processes.  a value of 
                             0 means disabled (default).  this only takes effect when used together with --lowmem. [default: 
                             0]
  -Q, --qoe                  set 'true' to enable QoE tracking. set 'dump' to dump QoE disklog to csv then exit [default: 
                             false]
  --qoelog                   Write QoE event logs to the QoE disklog file for post processing [default: ]
  --prometheus               Enable metrics collection via Prometheus. Usually used with --restapi to enable scraping 
                             endpoint.
  --restapi                  Enable REST API for monitoring and control. For now only serves /metrics. Can be set to IP:Port 
                             to listen on a specific IP and Port, or just Port to listen on all interfaces on that port. 
                             [default: disabled]
  --log_to                   Control where the log output goes. console: directly to the console      null: quietly, don't 
                             output any logs. [default: console]
```

For example, create 50K concurrent connections at the arrival rate of 100/sec:

```sh
./emqtt_bench conn -c 50000 -i 10
```

## Sub Benchmark

``` sh
Usage: emqtt_bench sub [--help <help>] [-d <dist>] [-h [<host>]] [-p [<port>]] [-V [<version>]] [-c [<count>]]
                       [-R [<conn_rate>]] [-i [<interval>]] [--ifaddr <ifaddr>] [--prefix <prefix>] [-s [<shortids>]]
                       [-n [<startnumber>]] [--num-retry-connect [<num_retry_connect>]] [-R [<conn_rate>]]
                       [--reconnect [<reconnect>]] [-S [<ssl>]] [--ssl-version <sslversion>] [--cacertfile <cacertfile>]
                       [--certfile <certfile>] [--keyfile <keyfile>] [--ciphers <ciphers>]
                       [--signature-algs <signature_algs>] [--keyex-algs <keyex_algs>] [--quic [<quic>]] [--ws [<ws>]]
                       [--load-qst <nst_dets_file>] [-u <username>] [-P <password>] [-k [<keepalive>]] [-C [<clean>]]
                       [-x [<expiry>]] [-l <lowmem>] [--force-major-gc-interval [<force_major_gc_interval>]] [-Q [<qoe>]]
                       [--qoelog [<qoelog>]] [--prometheus] [--restapi [<restapi>]] [--log_to [<log_to>]] [-t <topic>]
                       [--payload-hdrs [<payload_hdrs>]] [-q [<qos>]]

  --help                     help information
  -d, --dist                 enable distribution port
  -h, --host                 mqtt server hostname or comma-separated hostnames [default: localhost]
  -p, --port                 mqtt server port number [default: 1883]
  -V, --version              mqtt protocol version: 3 | 4 | 5 [default: 5]
  -c, --count                max count of clients [default: 200]
  -R, --connrate             connection rate(/s), default: 0, fallback to use --interval [default: 0]
  -i, --interval             interval of connecting to the broker [default: 10]
  --ifaddr                   local ipaddress or interface address
  --prefix                   Client ID prefix. If not provided '$HOST_bench_(pub|sub)_$RANDOM_$N' is used, where $HOST is 
                             either the host name or the IP address provided in the --ifaddr option, $RANDOM is a random 
                             number and $N is the sequence number assigned for each client. If provided, the $RANDOM suffix 
                             will not be added.
  -s, --shortids             Use short client ID. If --prefix is provided, the prefix is added otherwise client ID is the 
                             assigned sequence number. [default: false]
  -n, --startnumber          The start point when assigning sequence numbers to clients. This is useful when running 
                             multiple emqtt-bench instances to test the same broker (cluster), so the start number can be 
                             planned to avoid client ID collision [default: 0]
  --num-retry-connect        number of times to retry estabilishing a connection before giving up [default: 0]
  --reconnect                max retries of reconnects. 0: disabled [default: 0]
  -S, --ssl                  ssl socket for connecting to server [default: false]
  --ssl-version              enforce tls version and implies ssl is enabled, 'tlsv1.1' | 'tlsv1.2' | 'tlsv1.3' | 
                             'tlsv1.3_nocompat'
  --cacertfile               CA certificate for server verification
  --certfile                 client certificate for authentication, if required by server
  --keyfile                  client private key for authentication, if required by server
  --ciphers                  Cipher suite for ssl/tls connection, comma separated list. e.g. 
                             TLS_AES_256_GCM_SHA384,TLS_CHACHA20_POLY1305_SHA256
  --signature-algs           Signature algorithm for tlsv1.3 connection only, comma separated list. e.g. 
                             ecdsa_secp384r1_sha384,ecdsa_secp256r1_sha256
  --keyex-algs               Key exchange algorithm for tlsv1.3 connection only, comma separated list. e.g. 
                             secp384r1,secp256r1
  --quic                     QUIC transport [default: false]
  --ws                       websocket transport [default: false]
  --load-qst                 load quic session tickets from dets file
  -u, --username             username for connecting to server
  -P, --password             password for connecting to server
  -k, --keepalive            keep alive in seconds [default: 300]
  -C, --clean                clean session [default: true]
  -x, --session-expiry       Set 'Session-Expiry' for persistent sessions (seconds) [default: 0]
  -l, --lowmem               enable low mem mode, but use more CPU
  --force-major-gc-interval  interval in milliseconds in which a major GC will be forced on the bench processes.  a value of 
                             0 means disabled (default).  this only takes effect when used together with --lowmem. [default: 
                             0]
  -Q, --qoe                  set 'true' to enable QoE tracking. set 'dump' to dump QoE disklog to csv then exit [default: 
                             false]
  --qoelog                   Write QoE event logs to the QoE disklog file for post processing [default: ]
  --prometheus               Enable metrics collection via Prometheus. Usually used with --restapi to enable scraping 
                             endpoint.
  --restapi                  Enable REST API for monitoring and control. For now only serves /metrics. Can be set to IP:Port 
                             to listen on a specific IP and Port, or just Port to listen on all interfaces on that port. 
                             [default: disabled]
  --log_to                   Control where the log output goes. console: directly to the console      null: quietly, don't 
                             output any logs. [default: console]
  -t, --topic                topic subscribe, support %u, %c, %i variables
  --payload-hdrs             Handle the payload header from received message. Publish side must have the same option enabled 
                             in the same order. cnt64: Check the counter is strictly increasing. ts: publish latency 
                             counting, could be used for QoE tracking as well [default: ]
  -q, --qos                  subscribe qos [default: 0]
```

For example, create 50K concurrent connections at the arrival rate of 100/sec:

```sh
./emqtt_bench sub -c 50000 -i 10 -t bench/%i -q 2
```

## Pub Benchmark

``` sh
Usage: emqtt_bench pub [--help <help>] [-d <dist>] [-h [<host>]] [-p [<port>]] [-V [<version>]] [-c [<count>]]
                       [-R [<conn_rate>]] [-i [<interval>]] [--ifaddr <ifaddr>] [--prefix <prefix>] [-s [<shortids>]]
                       [-n [<startnumber>]] [--num-retry-connect [<num_retry_connect>]] [-R [<conn_rate>]]
                       [--reconnect [<reconnect>]] [-S [<ssl>]] [--ssl-version <sslversion>] [--cacertfile <cacertfile>]
                       [--certfile <certfile>] [--keyfile <keyfile>] [--ciphers <ciphers>]
                       [--signature-algs <signature_algs>] [--keyex-algs <keyex_algs>] [--quic [<quic>]] [--ws [<ws>]]
                       [--load-qst <nst_dets_file>] [-u <username>] [-P <password>] [-k [<keepalive>]] [-C [<clean>]]
                       [-x [<expiry>]] [-l <lowmem>] [--force-major-gc-interval [<force_major_gc_interval>]] [-Q [<qoe>]]
                       [--qoelog [<qoelog>]] [--prometheus] [--restapi [<restapi>]] [--log_to [<log_to>]]
                       [-I [<interval_of_msg>]] [-t <topic>] [--payload-hdrs [<payload_hdrs>]] [-s [<size>]] [-m <message>]
                       [--topics-payload <topics_payload>] [-q [<qos>]] [-r [<retain>]] [-L [<limit>]] [-F [<inflight>]]
                       [-w [<wait_before_publishing>]] [--max-random-wait [<max_random_wait>]]
                       [--min-random-wait [<min_random_wait>]] [--retry-interval [<retry_interval>]]

  --help                        help information
  -d, --dist                    enable distribution port
  -h, --host                    mqtt server hostname or comma-separated hostnames [default: localhost]
  -p, --port                    mqtt server port number [default: 1883]
  -V, --version                 mqtt protocol version: 3 | 4 | 5 [default: 5]
  -c, --count                   max count of clients [default: 200]
  -R, --connrate                connection rate(/s), default: 0, fallback to use --interval [default: 0]
  -i, --interval                interval of connecting to the broker [default: 10]
  --ifaddr                      local ipaddress or interface address
  --prefix                      Client ID prefix. If not provided '$HOST_bench_(pub|sub)_$RANDOM_$N' is used, where $HOST is 
                                either the host name or the IP address provided in the --ifaddr option, $RANDOM is a random 
                                number and $N is the sequence number assigned for each client. If provided, the $RANDOM 
                                suffix will not be added.
  -s, --shortids                Use short client ID. If --prefix is provided, the prefix is added otherwise client ID is the 
                                assigned sequence number. [default: false]
  -n, --startnumber             The start point when assigning sequence numbers to clients. This is useful when running 
                                multiple emqtt-bench instances to test the same broker (cluster), so the start number can be 
                                planned to avoid client ID collision [default: 0]
  --num-retry-connect           number of times to retry estabilishing a connection before giving up [default: 0]
  --reconnect                   max retries of reconnects. 0: disabled [default: 0]
  -S, --ssl                     ssl socket for connecting to server [default: false]
  --ssl-version                 enforce tls version and implies ssl is enabled, 'tlsv1.1' | 'tlsv1.2' | 'tlsv1.3' | 
                                'tlsv1.3_nocompat'
  --cacertfile                  CA certificate for server verification
  --certfile                    client certificate for authentication, if required by server
  --keyfile                     client private key for authentication, if required by server
  --ciphers                     Cipher suite for ssl/tls connection, comma separated list. e.g. 
                                TLS_AES_256_GCM_SHA384,TLS_CHACHA20_POLY1305_SHA256
  --signature-algs              Signature algorithm for tlsv1.3 connection only, comma separated list. e.g. 
                                ecdsa_secp384r1_sha384,ecdsa_secp256r1_sha256
  --keyex-algs                  Key exchange algorithm for tlsv1.3 connection only, comma separated list. e.g. 
                                secp384r1,secp256r1
  --quic                        QUIC transport [default: false]
  --ws                          websocket transport [default: false]
  --load-qst                    load quic session tickets from dets file
  -u, --username                username for connecting to server
  -P, --password                password for connecting to server
  -k, --keepalive               keep alive in seconds [default: 300]
  -C, --clean                   clean session [default: true]
  -x, --session-expiry          Set 'Session-Expiry' for persistent sessions (seconds) [default: 0]
  -l, --lowmem                  enable low mem mode, but use more CPU
  --force-major-gc-interval     interval in milliseconds in which a major GC will be forced on the bench processes.  a value 
                                of 0 means disabled (default).  this only takes effect when used together with --lowmem. 
                                [default: 0]
  -Q, --qoe                     set 'true' to enable QoE tracking. set 'dump' to dump QoE disklog to csv then exit [default: 
                                false]
  --qoelog                      Write QoE event logs to the QoE disklog file for post processing [default: ]
  --prometheus                  Enable metrics collection via Prometheus. Usually used with --restapi to enable scraping 
                                endpoint.
  --restapi                     Enable REST API for monitoring and control. For now only serves /metrics. Can be set to 
                                IP:Port to listen on a specific IP and Port, or just Port to listen on all interfaces on 
                                that port. [default: disabled]
  --log_to                      Control where the log output goes. console: directly to the console      null: quietly, 
                                don't output any logs. [default: console]
  -I, --interval_of_msg         interval of publishing message(ms) [default: 1000]
  -t, --topic                   topic subscribe, support %u, %c, %i, %s variables
  --payload-hdrs                 If set, add optional payload headers. cnt64: strictly increasing counter(64bit) per 
                                publisher ts: Timestamp when emit example: --payload-hdrs cnt64,ts [default: ]
  -s, --size                    payload size [default: 256]
  -m, --message                 Set the message content for publish. Either a literal message content, or path to a file 
                                with payload template specified via 'template://<file_path>'. Available variables: 
                                %TIMESTAMP%, %TIMESTAMPMS%, %TIMESTAMPUS%, %TIMESTAMPNS%, %UNIQUE%, %RANDOM%. When using 
                                'template://', --size option does not have effect except for when %RANDOM% placeholder is 
                                used.
  --topics-payload              json file defining topics and payloads
  -q, --qos                     subscribe qos [default: 0]
  -r, --retain                  retain message [default: false]
  -L, --limit                   The max message count to publish, 0 means unlimited [default: 0]
  -F, --inflight                maximum inflight messages for QoS 1 an 2, value 0 for 'infinity' [default: 1]
  -w, --wait-before-publishing  wait for all publishers to have (at least tried to) connected before starting publishing 
                                [default: false]
  --max-random-wait             maximum randomized period in ms that each publisher will wait before starting to publish 
                                (uniform distribution) [default: 0]
  --min-random-wait             minimum randomized period in ms that each publisher will wait before starting to publish 
                                (uniform distribution) [default: 0]
  --retry-interval              Publisher's resend interval (in seconds) if the expected acknowledgement for a inflight 
                                packet is not received within this interval. Default value 0 means no resend. [default: 0]

```
For example, create 100 connections and each publishes messages at the rate of 100 msg/sec.

```sh
./emqtt_bench pub -c 100 -I 10 -t bench/%i -s 256
```

## Local interface

```sh
./emqtt_bench pub --ifaddr 192.168.1.10
./emqtt_bench sub --ifaddr 192.168.2.10
```

## TLS/SSL (cliet certificate is not required by server)

```sh
./emqtt_bench sub -c 100 -i 10 -t bench/%i -p 8883 --ssl
./emqtt_bench pub -c 100 -I 10 -t bench/%i -p 8883 -s 256 --ssl
```

## TLS/SSL (client certificate is required by server)

```sh
./emqtt_bench sub -c 100 -i 10 -t bench/%i -p 8883 --ssl --certfile path/to/client-cert.pem --keyfile path/to/client-key.pem
./emqtt_bench pub -c 100 -i 10 -t bench/%i -s 256 -p 8883 --ssl --certfile path/to/client-cert.pem --keyfile path/to/client-key.pem
```

## Notice

You should not set '-c' option more than 64K for TCP ports limit on one source addresses,
however you can send messages from multiple source IP Addresses with '--ifaddr ' such like

```
./emqtt_bench sub -c 200000 -t "perf/test" --ifaddr 192.168.200.18,192.168.200.19,192.168.200.20,192.168.200.21
```

Make sure to increase resource usage limits and expand the port range like following on Linux.

``` sh
ulimit -n 200000
sudo sysctl -w net.ipv4.ip_local_port_range="1025 65534"
```

## Author

EMQX Team.

