defmodule JollaCNBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :jollacn_bot,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      applications: [],
      extra_applications: [
        :logger,
        :httpoison,
        :jason,
        :rbmq,
        :redix,
        :timex
      ],
      mod: {JollaCNBot.Application, []}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.4"},
      {:jason, "~> 1.1"},
      # {:amqp, "~> 1.0"}
      {:redix, ">= 0.0.0"},
      {:rbmq, git: "https://github.com/Nebo15/rbmq.git"},
      {:timex, "~> 3.1"}
    ]
  end
end
