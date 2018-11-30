defmodule JollaCNBot.Application do
  @moduledoc false

  use Application
  require Logger
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    basic_children = [
      # worker(JollaCNBot.Publish.Weibo, []),
      supervisor(JollaCNBot.Connection.RabbitMQ, []),
      {Redix, name: :redis}
    ]

    children =
      basic_children
      |> check_publish_weibo()
      |> check_subscribe_telegram()

    opts = [strategy: :one_for_one, name: JollaCNBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp check_publish_weibo(ori_children) do
    if Application.get_env(:jollacn_bot, :publish_weibo, nil) == nil do
      ori_children
    else
      Logger.info("including publish weibo")

      ori_children ++
        [
          worker(JollaCNBot.Publish.Weibo.Publisher, []),
          worker(JollaCNBot.Publish.Weibo.RabbitProducer, [])
        ]
    end
  end

  defp check_subscribe_telegram(ori_children) do
    if Application.get_env(:jollacn_bot, :subscribe_telegram, nil) == nil do
      ori_children
    else
      # throw "including telegram subscribe"
      Logger.info("including subscribe telegram")
      ori_children ++ [worker(JollaCNBot.Subscribe.Telegram.RabbitConsumer, [])]
    end
  end
end
