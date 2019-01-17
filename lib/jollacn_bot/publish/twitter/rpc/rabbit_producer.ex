defmodule JollaCNBot.Publish.Twitter.RPC.RabbitProducer do
  use RBMQ.Producer,
    connection: JollaCNBot.Connection.RabbitMQ,
    queue: [
      {:durable, true},
      {:no_ack, true}
      | :jollacn_bot
        |> Application.get_env(:publish_twitter, [])
        |> Keyword.get(:producer, [])
        |> Keyword.get(:queue, [])
    ],
    exchange: [
      {:type, :fanout},
      {:durable, true}
      | :jollacn_bot
        |> Application.get_env(:publish_twitter, [])
        |> Keyword.get(:producer, [])
        |> Keyword.get(:exchange, [])
    ],
    options: [
      durable: true
    ]
end
