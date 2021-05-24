# Erlang MQTT Benchmark Tool

`emqtt_bench` is a simple MQTT v5.0 benchmark tool written in Erlang.

Requires Erlang/OTP 22.3+ to build.

## Build first

```sh
make
```

## Connect Benchmark

```sh
$ ./emqtt_bench conn --help
Usage: emqtt_bench conn [--help <help>] [-h [<host>]] [-p [<port>]]
                        [-c [<count>]] [-n [<startnumber>]]
                        [-i [<interval>]] [-u <username>] [-P <password>]
                        [-k [<keepalive>]] [-C [<clean>]] [-S [<ssl>]]
                        [--certfile <certfile>] [--keyfile <keyfile>]
                        [--ifaddr <ifaddr>] [--prefix <prefix>]

  --help             help information
  -h, --host         mqtt server hostname or IP address [default:
                     localhost]
  -p, --port         mqtt server port number [default: 1883]
  -V, --version      mqtt protocol version: 3 | 4 | 5 [default: 5]
  -c, --count        max count of clients [default: 200]
  -n, --startnumber  start number [default: 0]
  -i, --interval     interval of connecting to the broker [default: 10]
  -u, --username     username for connecting to server
  -P, --password     password for connecting to server
  -k, --keepalive    keep alive in seconds [default: 300]
  -C, --clean        clean session [default: true]
  -S, --ssl          ssl socoket for connecting to server [default: false]
  --certfile         client certificate for authentication, if required by
                     server
  --keyfile          client private key for authentication, if required by
                     server
  --ifaddr           One or multiple (comma-separated) source IP addresses
  --prefix           client id prefix
  -l, --lowmem       low mem mode, but use more CPU 
```

For example, create 50K concurrent connections at the arrival rate of 100/sec:

```sh
./emqtt_bench conn -c 50000 -i 10
```

## Sub Benchmark

```sh
$ ./emqtt_bench sub --help
Usage: emqtt_bench sub [--help <help>] [-h [<host>]] [-p [<port>]]
                       [-V [<version>]] [-c [<count>]]
                       [-n [<startnumber>]] [-i [<interval>]]
                       [-t <topic>] [-q [<qos>]] [-u <username>]
                       [-P <password>] [-k [<keepalive>]] [-C [<clean>]]
                       [-S [<ssl>]] [--certfile <certfile>]
                       [--keyfile <keyfile>] [--ws [<ws>]]
                       [--ifaddr <ifaddr>] [--prefix <prefix>]

  --help             help information
  -h, --host         mqtt server hostname or IP address [default: localhost]
  -p, --port         mqtt server port number [default: 1883]
  -V, --version      mqtt protocol version: 3 | 4 | 5 [default: 5]
  -c, --count        max count of clients [default: 200]
  -n, --startnumber  start number [default: 0]
  -i, --interval     interval of connecting to the broker [default: 10]
  -t, --topic        topic subscribe, support %u, %c, %i variables
  -q, --qos          subscribe qos [default: 0]
  -u, --username     username for connecting to server
  -P, --password     password for connecting to server
  -k, --keepalive    keep alive in seconds [default: 300]
  -C, --clean        clean start [default: true]
  -S, --ssl          ssl socoket for connecting to server [default: false]
  --certfile         client certificate for authentication, if required by server
  --keyfile          client private key for authentication, if required by server
  --ws               websocket transport [default: false]
  --ifaddr           local ipaddress or interface address
  --prefix           client id prefix
  -l, --lowmem       low mem mode, but use more CPU
```

For example, create 50K concurrent connections at the arrival rate of 100/sec: 

```sh
./emqtt_bench sub -c 50000 -i 10 -t bench/%i -q 2
```

## Pub Benchmark

```sh
$ ./emqtt_bench pub --help
Usage: emqtt_bench pub [--help <help>] [-h [<host>]] [-p [<port>]]
                       [-V [<version>]] [-c [<count>]]
                       [-n [<startnumber>]] [-i [<interval>]]
                       [-I [<interval_of_msg>]] [-u <username>]
                       [-P <password>] [-t <topic>] [-s [<size>]]
                       [-q [<qos>]] [-r [<retain>]] [-k [<keepalive>]]
                       [-C [<clean>]] [-S [<ssl>]]
                       [--certfile <certfile>] [--keyfile <keyfile>]
                       [--ws [<ws>]] [--ifaddr <ifaddr>] [--prefix <prefix>]

  --help                 help information
  -h, --host             mqtt server hostname or IP address [default: localhost]
  -p, --port             mqtt server port number [default: 1883]
  -V, --version          mqtt protocol version: 3 | 4 | 5 [default: 5]
  -c, --count            max count of clients [default: 200]
  -n, --startnumber      start number [default: 0]
  -i, --interval         interval of connecting to the broker [default: 10]
  -I, --interval_of_msg  interval of publishing message(ms) [default: 1000]
  -u, --username         username for connecting to server
  -P, --password         password for connecting to server
  -t, --topic            topic subscribe, support %u, %c, %i variables
  -s, --size             payload size [default: 256]
  -q, --qos              subscribe qos [default: 0]
  -r, --retain           retain message [default: false]
  -k, --keepalive        keep alive in seconds [default: 300]
  -C, --clean            clean start [default: true]
  -L, --limit            The max message count to publish, 0 means unlimited [default: 0]
  -S, --ssl              ssl socoket for connecting to server [default: false]
  --certfile             client certificate for authentication, if required by server
  --keyfile              client private key for authentication, if required by server
  --ws                   websocket transport [default: false]
  --ifaddr               One or multiple (comma-separated) source IP addresses
  --prefix               client id prefix
  -l, --lowmem       low mem mode, but use more CPU 
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

## One-way SSL Socket

```sh
./emqtt_bench sub -c 100 -i 10 -t bench/%i -p 8883 -S
./emqtt_bench pub -c 100 -I 10 -t bench/%i -p 8883 -s 256 -S
```

## Two-way SSL Socket
```sh
./emqtt_bench sub -c 100 -i 10 -t bench/%i -p 8883 --certfile path/to/client-cert.pem --keyfile path/to/client-key.pem
./emqtt_bench pub -c 100 -i 10 -t bench/%i -s 256 -p 8883 --certfile path/to/client-cert.pem --keyfile path/to/client-key.pem
```

## Notice

You should not set '-c' option more than 64K for TCP ports limit on one source addresses, 
however you can send messages from multiple source IP Addresses with '--ifaddr ' such like

./emqtt_bench sub -c 200000 -t "perf/test" --ifaddr 192.168.200.18,192.168.200.19,192.168.200.20,192.168.200.21

ensure you ulimit the fds and expand the port range like following on Linux.

``` sh
ulimit -n 200000
sudo sysctl -w net.ipv4.ip_local_port_range="1025 65534"
```

## Author

EMQ X Team.

