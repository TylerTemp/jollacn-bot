defmodule JollaCNBot.Publish.Boardcast do
  use RBMQ.Producer,
    connection: JollaCNBot.Connection.RabbitMQ,
    # Queue params
    queue: [
      {:durable, true}
      | :jollacn_bot
        |> Application.fetch_env!(:publish_channel)
        |> Keyword.fetch!(:queue)
    ],
    exchange: [
      {:type, :fanout},
      {:durable, true}
      | :jollacn_bot
        |> Application.fetch_env!(:publish_channel)
        |> Keyword.fetch!(:exchange)
    ],
    options: [
      durable: true
    ]
end
