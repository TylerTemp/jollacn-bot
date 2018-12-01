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

  def consume(payload, tag: tag, redelivered?: _redelivered) do
    # ack(tag)
    payload
    |> Jason.decode!()
    |> deliver_message()

    # :ok
    ack(tag)
  end

  def deliver_message(%{"type" => "weibo_comment"} = weibo_comment) do
    # Logger.debug("rabbit deliver_message: #{inspect(weibo_comment)}")
    JollaCNBot.TelegramBot.Worker.push_weibo_comment(weibo_comment)
  end

  def deliver_message(%{}) do
    :ok
  end
end
