use Mix.Config

# t.me/Jollacn_bot

config :logger,
  # handle_otp_reports: false,
  # backends: [{LoggerFileBackend, :json_log}]
  # backends: [:console]
  backends: [:console]

config :logger, :console,
  # format: {JollaCNBot.Util.Logger, :pretty_console},
  format: "$date $time [$level] $message\n",
  # metadata: :all,
  level: :debug

# config :jollacn_bot, JollaCNBot.Connection.RabbitMQ,
#   host: {:system, "AMQP_HOST", "localhost"},
#   port: {:system, "AMQP_PORT", 5672},
#   username: {:system, "AMQP_USER", "guest"},
#   password: {:system, "AMQP_PASSWORD", "guest"},
#   virtual_host: {:system, "AMQP_VHOST", "/"},
#   connection_timeout: {:system, "AMQP_TIMEOUT", 15_000}

config :jollacn_bot, JollaCNBot.Connection.RabbitMQ,
  host: "localhost",
  port: 5672,
  username: "guest",
  password: "guest",
  virtual_host: "/",
  connection_timeout: 15_000


config :jollacn_bot, :publish_channel,
  queue: [
    name: "test_pubsub3_queue",
    # error_name: "test_pubsub3_queue_error",
    routing_key: "test_pubsub3_queue"
  ],
  exchange: [
    name: "test_pubsub3_exchange"
  ]



case Mix.env() do
  env = :prod ->
    import_config "#{env}.exs"

  env ->
    config_file = "#{env}.exs"

    if File.exists?(Path.join([__DIR__, config_file])) do
      IO.puts("import config #{config_file}")
      import_config config_file
      IO.puts("config #{config_file} loaded")
    end
end
