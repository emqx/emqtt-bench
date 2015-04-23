# emqttd benchmark

## Build first

```sh
make 
```

## Run

```sh
./run Host Port MaxClients Interval
```
Paramter    |   Description
------------|--------------
Host        | MQTT Broker Host
Port        | MQTT Broker Port
MaxClients  | Max Concurrent Clients
Interval    | Interval(millsecs) between starting connections

## Notice

Usually, you cannot set MaxClients more than 65535 for TCP ports limit...

## Contact

feng@emqtt.io

