use Mix.Config

config :jollacn_bot, :publish_twitter,
  consumer: [
    queue: [
      name: "t_callback"
    ]
  ],
  producer: [
    queue: [
      name: "t_queue",
      routing_key: "t_queue"
    ],
    exchange: [
      name: "t_exchange"
    ]
  ],
  # run every 15 mins
  interval: 1_000 * 60 * 15

IO.puts("config worker/#{Path.basename(__ENV__.file)} loaded")
