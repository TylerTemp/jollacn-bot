defmodule JollaCNBot.Publish.Twitter.RPC.RabbitConsumer do
  # Callback
  use RBMQ.Consumer,
    connection: JollaCNBot.Connection.RabbitMQ,
    queue:
      :jollacn_bot
      |> Application.fetch_env!(:publish_twitter)
      |> Keyword.fetch!(:consumer)
      |> Keyword.fetch!(:queue),
    qos: [
      prefetch_count: 5
    ],
    options: [
      durable: true,
      no_ack: true
    ]

  # def consume(payload, %{tag: tag, redelivered: _redelivered}) do
  def consume(payload, _props) do
    # ack(tag)
    # IO.puts("payload = #{payload}")
    # :ok
    payload
    |> Jason.decode!()
    |> JollaCNBot.Publish.Twitter.Publisher.deliver_message()
  end
end
