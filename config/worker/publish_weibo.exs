use Mix.Config

config :jollacn_bot, :publish_weibo,
  # run every 15 mins
  interval: 1_000 * 60 * 15

IO.puts("config worker/#{Path.basename(__ENV__.file)} loaded")
