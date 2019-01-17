# JollaCNBot

## requirement

```
sudo apt-get install pandoc
sudo apt-get install redis-server
```

also need postgres and elixir

## redis storage

key | type | comment
----|------|---------
`msg_status:{msg_id}` | string | if message is delivered to broker
`msg_list:{channel}` | list | `{msg_id}` container for cache control, in case it goes too big
`tg:sub:{channel}` | set | subscribed chats
`tg:handle:{id}` | string | if a telegram message has been dealt
`tg:handle_list` | list | handled message, in case it goes too big


## release ##

```bash
cd ~/source/jollacn_bot
export version="$(cat mix.exs | grep version | awk '{print substr($2, 2, length($2)-3)}')"
echo "version=${version}"

cd ~/source/jollacn_bot
MIX_ENV=prod mix release --env=prod
mkdir -p ~/release/jollacn_bot
cp _build/prod/rel/jollacn_bot/releases/${version}/jollacn_bot.tar.gz ~/release/jollacn_bot/

cd ~/release/jollacn_bot
tar -xzf jollacn_bot.tar.gz

sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start 'jollacn_bot'
```

## upgrade ##

```bash
cd ~/source/jollacn_bot
export version="$(cat mix.exs | grep version | awk '{print substr($2, 2, length($2)-3)}')"
echo "version=${version}"

# upgrade
cd ~/source/jollacn_bot
MIX_ENV=prod mix release --upgrade --env=prod
mkdir -p ~/release/jollacn_bot/releases/${version} && cp _build/prod/rel/jollacn_bot/releases/${version}/jollacn_bot.tar.gz ~/release/jollacn_bot/releases/${version}/jollacn_bot.tar.gz

# do upgrade:
cd ~/release/jollacn_bot
bin/jollacn_bot upgrade "${version}"
```
