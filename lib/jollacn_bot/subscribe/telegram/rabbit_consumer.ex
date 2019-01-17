defmodule JollaCNBot.Subscribe.Telegram.RabbitConsumer do
  use RBMQ.Consumer,
    connection: JollaCNBot.Connection.RabbitMQ,
    # Queue params
    queue: [
      name:
        :jollacn_bot
        |> Application.fetch_env!(:publish_channel)
        # |> Keyword.fetch!(:exchange)
        |> Keyword.fetch!(:queue)
        |> Keyword.fetch!(:name)
    ],
    qos: [
      prefetch_count: 5
    ],
    options: [
      durable: true
    ]

  def consume(payload, %{tag: tag, redelivered: _redelivered}) do
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

  def deliver_message(%{"type" => "twitter_post"} = twitter_post) do
    JollaCNBot.TelegramBot.Worker.push_twitter_post(twitter_post)
  end

  def deliver_message(%{}) do
    :ok
  end
end
