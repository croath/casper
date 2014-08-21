casper
======

TCP/UDP socket sample:

`telnet 127.0.0.1 9092`

```json
{
  "notifications": [
    {
      "push_token": "4bc866df0385648104ca9a55cc5a8212c18b4900f7d0d2838d45f6895792f06e",
      "alert": "Receive a message from user_001",
      "badge": 4,
      "params": "{\"json\":\"a sample json\"}",
      "type": "iOS"
    },
    {
      "push_token": "3bc866df0385648104ca9a55cc5a8212c18b4900f7d0d2838d45f6895792f06e",
      "alert": "Receive a message from user_002",
      "badge": 1,
      "params": "{\"json\":\"another sample json\"}",
      "type": "iOS"
    }
  ]
}
```

HTTP sample:

HTTP `POST /push/send.json`

parameters:

```json
"push_token": "4bc866df0385648104ca9a55cc5a8212c18b4900f7d0d2838d45f6895792f06e"

"alert": "Receive a message from user_001"

"badge": "4"

"params": "{\"json\":\"a sample json\"}"

"type": "iOS"
```
