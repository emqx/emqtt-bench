# emqtt benchmark

This is a simple MQTT benchmark tool written in Erlang. The main purpose of the tool is to benchmark how many concurrent connections a MQTT broker could support.

## Build first

```sh
make 
```

## Sub Benchmark

```sh
$ ./emqtt_bench_sub --help
Usage: emqtt_bench_sub [--help <help>] [-h [<host>]] [-p [<port>]]
                       [-c [<count>]] [-i [<interval>]] [-t <topic>]
                       [-q [<qos>]] [-u <username>] [-P <password>]
                       [-k [<keepalive>]] [-C [<clean>]]
                       [--ifaddr <ifaddr>]

  --help           help information
  -h, --host       mqtt server hostname or IP address [default: localhost]
  -p, --port       mqtt server port number [default: 1883]
  -c, --count      max count of clients [default: 200]
  -i, --interval   interval of connecting to the broker [default: 10]
  -t, --topic      topic subscribe, support %u, %c, %i variables
  -q, --qos        subscribe qos [default: 0]
  -u, --username   username for connecting to server
  -P, --password   password for connecting to server
  -k, --keepalive  keep alive in seconds [default: 300]
  -C, --clean      clean session [default: true]
  --ifaddr         local ipaddress or interface address
```

For example, create 50K concurrent clients at the arrival rate of 100/sec: 

```sh
./emqtt_bench_sub -c 50000 -i 10 -t bench/%i -q 2
```

## Pub Benchmark

```sh
$ ./emqtt_bench_pub --help
Usage: emqtt_bench_pub [--help <help>] [-h [<host>]] [-p [<port>]]
                       [-c [<count>]] [-i [<interval>]]
                       [-I [<interval_of_msg>]] [-u <username>]
                       [-P <password>] [-t <topic>] [-s [<size>]]
                       [-q [<qos>]] [-r [<retain>]] [-k [<keepalive>]]
                       [-C [<clean>]] [--ifaddr <ifaddr>]

  --help                 help information
  -h, --host             mqtt server hostname or IP address [default:
                         localhost]
  -p, --port             mqtt server port number [default: 1883]
  -c, --count            max count of clients [default: 200]
  -i, --interval         interval of connecting to the broker [default: 10]
  -I, --interval_of_msg  interval of publishing message(ms) [default: 1000]
  -u, --username         username for connecting to server
  -P, --password         password for connecting to server
  -t, --topic            topic subscribe, support %u, %c, %i variables
  -s, --size             payload size [default: 256]
  -q, --qos              subscribe qos [default: 0]
  -r, --retain           retain message [default: false]
  -k, --keepalive        keep alive in seconds [default: 300]
  -C, --clean            clean session [default: true]
  --ifaddr               local ipaddress or interface address
```

For example, create 100 clients and each client publish messages at the rate of 100 msg/sec.

```sh
./emqtt_bench_pub -c 100 -I 10 -t bench/%i -s 256
```

## Local interface

```sh
./emqtt_bench_pub --ifaddr 192.168.1.10
./emqtt_bench_sub --ifaddr 192.168.2.10
```

## Notice

You should not set '-c' option more than 60K for TCP ports limit on one interface.

## Author

Feng Lee <feng@emqtt.io>

