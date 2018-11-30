defmodule JollaCNBot.Subscribe.Telegram.RabbitConsumer do
  use RBMQ.Consumer,
    connection: JollaCNBot.Connection.RabbitMQ,
    # Queue params
    queue: [
      durable: true,
      name:
        :jollacn_bot
        |> Application.fetch_env!(:publish_channel)
        # |> Keyword.fetch!(:exchange)
        |> Keyword.fetch!(:queue)
        |> Keyword.fetch!(:name)
    ],
    qos: [
      prefetch_count: 5
    ]

  def consume(payload, tag: _tag, redelivered?: _redelivered) do
    # ack(tag)
    IO.puts("received: #{payload}")
    # throw "error consume message"
    :ok
  end
end
