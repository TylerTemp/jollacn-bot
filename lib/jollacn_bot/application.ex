defmodule JollaCNBot.Application do
  @moduledoc false

  use Application
  require Logger
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    basic_children = [
      # worker(JollaCNBot.Publish.Weibo, []),
      supervisor(JollaCNBot.Connection.RabbitMQ, []),
      {Redix, name: :redis},
      worker(JollaCNBot.Publish.Boardcast, [])
    ]

    children =
      basic_children
      |> check_subscribe_telegram()
      |> check_telegram_bot()
      |> check_publish_weibo()
      |> check_publish_twitter()

    opts = [strategy: :one_for_one, name: JollaCNBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp check_subscribe_telegram(ori_children) do
    if Application.get_env(:jollacn_bot, :subscribe_telegram, nil) == nil do
      ori_children
    else
      Logger.info("including subscribe telegram")
      ori_children ++ [worker(JollaCNBot.Subscribe.Telegram.RabbitConsumer, [])]
    end
  end

  def check_telegram_bot(ori_children) do
    telegram_bot_config = Application.get_env(:jollacn_bot, :telegram_bot, [])

    if Keyword.get(telegram_bot_config, :is_active, false) do
      Logger.info("including telegram bot #{inspect(telegram_bot_config)}")
      port = Keyword.fetch!(telegram_bot_config, :port)

      ori_children ++
        [
          worker(JollaCNBot.TelegramBot.Worker, []),
          Plug.Cowboy.child_spec(
            scheme: :http,
            plug: JollaCNBot.TelegramBot.Router,
            options: [port: port]
          )
        ]
    else
      ori_children
    end
  end

  defp check_publish_weibo(ori_children) do
    if Application.get_env(:jollacn_bot, :publish_weibo, nil) == nil do
      ori_children
    else
      Logger.info("including publish weibo")

      ori_children ++
        [
          worker(JollaCNBot.Publish.Weibo.Publisher, [])
        ]
    end
  end

  defp check_publish_twitter(ori_children) do
    if Application.get_env(:jollacn_bot, :publish_twitter, nil) == nil do
      ori_children
    else
      Logger.info("including publish twitter")

      ori_children ++
        [
          worker(JollaCNBot.Publish.Twitter.Publisher, []),
          worker(JollaCNBot.Publish.Twitter.RPC.RabbitProducer, []),
          worker(JollaCNBot.Publish.Twitter.RPC.RabbitConsumer, [])
        ]
    end
  end
end
