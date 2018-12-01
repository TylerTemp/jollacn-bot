use Mix.Config

config :jollacn_bot, subscribe_telegram: true

IO.puts("config worker/#{Path.basename(__ENV__.file)} loaded")
