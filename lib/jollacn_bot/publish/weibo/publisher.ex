defmodule JollaCNBot.Publish.Weibo.Publisher do
  use GenServer
  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    weibo_comment_loop(3_000)
    {:ok, state}
  end

  def handle_info(:weibo_comment, state) do
    start_time = :os.system_time(:milli_seconds)
    Logger.debug("Publish.Weibo.Publisher starts")
    weibo_comment()
    cost_seconds = (:os.system_time(:milli_seconds) - start_time) / 1000
    Logger.info("Publish.Weibo.Publisher ends in #{cost_seconds} seconds")
    weibo_comment_loop()
    {:noreply, state}
  end

  # defp weibo_comment() do
  #   IO.puts("insert msg")
  #   JollaCNBot.Publish.Weibo.RabbitProducer.publish("test 1")
  #   JollaCNBot.Publish.Weibo.RabbitProducer.publish("test 2")
  #   JollaCNBot.Publish.Weibo.RabbitProducer.publish("test 3")
  #   IO.puts("insert msg done")
  # end

  defp weibo_comment() do
    case JollaCNBot.API.Weibo.run() do
      {:error, _} ->
        :error

      {:ok, blog_with_comments} ->
        Enum.each(blog_with_comments, fn
          %{
            "ok" => true,
            "comments_ok" => true,
            "id" => blog_id,
            "text" => blog_text,
            "comments" => comments
          } ->
            publish_count =
              comments
              |> Enum.map(fn
                %{
                  "ok" => true,
                  "id" => comment_id,
                  "text" => comment_text,
                  "user_name" => comment_user_name,
                  "url" => url
                } ->
                  msg_id = "weibo_comment:#{blog_id}:#{comment_id}"

                  msg_content = %{
                    "type" => "weibo_comment",
                    "id" => msg_id,
                    "blog_text" => blog_text,
                    "blog_id" => blog_id,
                    "comment_id" => comment_id,
                    "comment_text" => comment_text,
                    "user_name" => comment_user_name,
                    "url" => url
                  }

                  case Redix.command(:redis, ["GET", "msg_status:#{msg_id}"]) do
                    {:ok, nil} ->
                      # publish here
                      # IO.puts("GET result nil")
                      publish_result =
                        msg_content
                        |> Jason.encode!()
                        |> JollaCNBot.Publish.Weibo.RabbitProducer.publish()

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
                            ["RPUSH", "msg_list:weibo_comment", msg_id]
                          ]
                        )
                      end

                      publish_result

                    {:ok, _pub_readable_time} ->
                      # already published
                      # Logger.debug(
                      #   "msg already published at #{pub_readable_time}, #{comment_text}"
                      # )

                      :skip

                    {:error, reason} ->
                      Logger.error(
                        "failed to execute redis command GET msg_status:#{msg_id}: #{
                          inspect(reason)
                        }"
                      )

                      :error
                  end

                %{"ok" => true} = comment ->
                  Logger.error(
                    "weibo publisher failed to understand API comment result: #{inspect(comment)}"
                  )

                  :error

                comment ->
                  Logger.error(
                    "weibo publisher failed to accept API comment result: #{inspect(comment)}"
                  )

                  :error
              end)
              |> Enum.count(fn result -> result == :ok end)

            if publish_count > 0 do
              Logger.info("weibo publisher published #{publish_count} message(s)")
            end

          %{"ok" => true, "comments_ok" => true} = blog ->
            Logger.error("weibo publisher failed to understand API blog result: #{inspect(blog)}")
            :error

          blog ->
            Logger.error("weibo publisher failed to accept API blog result: #{inspect(blog)}")
            :error
        end)
    end
  end

  defp weibo_comment_loop() do
    :jollacn_bot
    |> Application.fetch_env!(:publish_weibo)
    |> Keyword.fetch!(:interval)
    |> weibo_comment_loop()
  end

  defp weibo_comment_loop(interval) do
    Logger.debug("Publish.Weibo.Publisher will work in #{interval / 1000} seconds")
    Process.send_after(self(), :weibo_comment, interval)
  end
end
