defmodule JollaCNBot.Publish.Twitter.Publisher do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    # first time always wait
    twitter_loop(0)
    {:ok, state}
  end

  def twitter_loop() do
    :jollacn_bot
    |> Application.fetch_env!(:publish_twitter)
    |> Keyword.fetch!(:interval)
    |> twitter_loop()
  end

  def twitter_loop(interval) do
    Logger.debug("Publish.Weibo.Publisher will work in #{interval / 1000} seconds")
    Process.send_after(self(), :twitter_loop, interval)
  end

  def twitter() do
    [
      %{
        "url" => "https://twitter.com/jollahq"
      }
    ]
    |> Jason.encode!()
    |> JollaCNBot.Publish.Twitter.RPC.RabbitProducer.publish(
      reply_to: "t_callback",
      correlation_id: "#{:os.system_time(:milli_seconds)}"
    )
  end

  def handle_info(:twitter_loop, state) do
    start_time = :os.system_time(:milli_seconds)
    Logger.debug("Publish.Twitter.RPC.Publisher starts")
    twitter()
    cost_seconds = (:os.system_time(:milli_seconds) - start_time) / 1000
    Logger.info("Publish.Twitter.RPC.Publisher ends in #{cost_seconds} seconds")
    twitter_loop()
    {:noreply, state}
  end

  def deliver_message(twitts) do
    # Logger.debug(fn ->
    #   "get twitters #{length(twitts)} to deliver"
    # end)
    publish_count =
      twitts
      |> Enum.map(fn %{
                       "url" => _url,
                       "at" => at,
                       "name" => owner_name,
                       "items" => items
                     } ->
        items
        |> Enum.map(fn %{"id" => item_id} = item ->
          msg_id = "t_#{at}_#{item_id}"

          msg_content =
            Map.merge(item, %{
              "id" => msg_id,
              "type" => "twitter_post",
              "owner_name" => owner_name
            })

          case Redix.command(:redis, ["GET", "msg_status:#{msg_id}"]) do
            {:ok, nil} ->
              # Logger.debug(fn ->
              #   "push twitter #{inspect msg_content}"
              # end)
              publish_result =
                msg_content
                |> Jason.encode!()
                |> JollaCNBot.Publish.Boardcast.publish()

              # publish will return :ok if succeed
              if publish_result == :ok do
                current_time_readable =
                  "Asia/Shanghai"
                  |> Timex.now()
                  |> Timex.format!("%F %T", :strftime)

                Redix.pipeline(
                  :redis,
                  [
                    ["SET", "msg_status:#{msg_id}", current_time_readable],
                    ["RPUSH", "msg_list:twitter_post", msg_id]
                  ]
                )
              end

              publish_result

            {:ok, _pub_readable_time} ->
              # already published
              # Logger.debug(
              #   "twitter already published at #{pub_readable_time}, #{inspect msg_content}"
              # )

              :skip

            {:error, reason} ->
              Logger.error(
                "failed to execute redis command GET msg_status:#{msg_id}: #{inspect(reason)}"
              )

              :error
          end
        end)
        |> Enum.filter(fn result -> result == :ok end)
      end)
      |> List.flatten()
      |> Enum.count()

    if publish_count > 0 do
      Logger.info("twitter publisher published #{publish_count} message(s)")
    end
  end
end
