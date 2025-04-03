# Publisher's Topics config file

This JSON structure is a configuration file defines how every publisher publishs more than one topics.

It defines topics and their associated properties.

## Fields and Their Meanings

### topics array:

Contains a list of topic definitions.

### name string:

The unique identifier or name of the MQTT topic.
support templating with %i, %c, %u

### interval_ms string:

The interval in milliseconds between message injections for the topic.
inject_timestamp boolean or string:

Controls whether a timestamp should be injected into the payload.
If true, a timestamp is injected.
If a string (e.g., "ms"), the timestamp format is specified.

### QoS integer:

The Quality of Service level for the topic.

### payload_encoding string:

The encoding format for the payload data.

"eterm" for Erlang Term Format.

"json" for json.

### payload object:

The data payload for the topic, containing key-value pairs.

### timestamp:

The initial timestamp or a placeholder.
    
### Data: The actual data template to be transmitted.
Other fields (e.g., foo1, foo2, VIN) might have specific meanings depending on the application.

### stream integer:

A logical stream identifier.

Must be 0 for None QUIC transport.

### stream_priority integer:

The priority of the stream for the topic. Higher values indicate higher importance.

### render string (optional):

how the data should be rendered with placeholder

