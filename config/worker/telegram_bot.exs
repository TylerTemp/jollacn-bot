use Mix.Config

config :jollacn_bot, :telegram_bot,
  is_active: true,
  port: 9000,
  # 1 hour
  get_updates_interval: 1_000 * 60 * 60,
  notice_mode: :pull

IO.puts("config worker/#{Path.basename(__ENV__.file)} loaded")
