# JollaCNBot

## requirement

```
sudo apt-get install pandoc
sudo apt-get install redis-server
```

## redis storage

key | type | comment
----|------|---------
`msg_status:{msg_id}` | string | if message is delivered to broker
`msg_list:{channel}` | list | `{msg_id}` container for cache control, in case it goes too big
`tg:sub:{channel}` | set | subscribed chats
`tg:handle:{id}` | string | if a telegram message has been dealt
`tg:handle_list` | list | handled message, in case it goes too big
