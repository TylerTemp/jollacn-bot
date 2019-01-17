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
      durable: true,
      no_ack: false
    ]

  def consume(payload, props) do
    # ack(tag)
    # ...?
    if Map.has_key?(props, :tag) do
      props
      |> Map.fetch!(:tag)
      |> ack()
    end

    payload
    |> Jason.decode!()
    |> deliver_message()
  end

  def deliver_message(%{"type" => "weibo_comment"} = weibo_comment) do
    Logger.debug("telegram get weibo_comment #{Map.get(weibo_comment, "id", nil)} to push")
    JollaCNBot.TelegramBot.Worker.push_weibo_comment(weibo_comment)
  end

  def deliver_message(%{"type" => "twitter_post"} = twitter_post) do
    Logger.debug("telegram get twitter_post #{Map.get(twitter_post, "id", nil)} to push")
    JollaCNBot.TelegramBot.Worker.push_twitter_post(twitter_post)
  end

  def deliver_message(%{}) do
    :ok
  end
end
