defmodule JollaCNBot.Publish.Twitter.RPC.RabbitProducer do
  use RBMQ.Producer,
    connection: JollaCNBot.Connection.RabbitMQ,
    queue: [
      {:durable, true},
      {:no_ack, true}
      | :jollacn_bot
        |> Application.fetch_env!(:publish_twitter)
        |> Keyword.fetch!(:producer)
        |> Keyword.fetch!(:queue)
    ],
    exchange: [
      {:type, :fanout},
      {:durable, true}
      | :jollacn_bot
        |> Application.fetch_env!(:publish_twitter)
        |> Keyword.fetch!(:producer)
        |> Keyword.fetch!(:exchange)
    ],
    options: [
      durable: true
    ]
end
