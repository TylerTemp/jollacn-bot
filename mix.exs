defmodule JollaCNBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :jollacn_bot,
      version: "0.1.2",
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
        :timex,
        :plug,
        :pandex
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
      {:rbmq, git: "https://github.com/TylerTemp/rbmq.git"},
      {:timex, "~> 3.1"},
      {:plug_cowboy, "~> 2.0"},
      {:pandex, "~> 0.1.0"}
    ]
  end
end
