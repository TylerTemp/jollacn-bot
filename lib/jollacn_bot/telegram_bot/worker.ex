defmodule JollaCNBot.TelegramBot.Worker do
  use GenServer
  require Logger

  def start_link(state \\ %{}) do
    Logger.debug("genserver registered name as #{__MODULE__}")
    # throw "fuck you as #{__MODULE__}"
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    get_updates_loop(0)
    {:ok, state}
  end

  # TODO: proper way to unsub?
  def handle_call({:sub_weibo_comment, chat_id}, _from, state) do
    result =
      case Redix.command(:redis, ["SADD", "tg:sub:weibo_comment", "#{chat_id}"]) do
        {:error, reason} = result ->
          Logger.error(
            "failed to execute redis SADD tg:sub:weibo_comment #{chat_id}: #{inspect(reason)}"
          )

          result

        {:ok, 0} ->
          {:ok, :exist}

        {:ok, 1} ->
          Logger.info("new sub on weibo comment #{chat_id}")
          {:ok, chat_id}
      end

    {:reply, result, state}
  end

  # def handle_info({:sub_weibo_comment, chat_id}, state) do
  #   {:reply, _result, new_state} = handle_call({:sub_weibo_comment, chat_id}, self(), state)
  #   {:noreply, new_state}
  # end

  def handle_cast(
        {:push_weibo_comment,
         %{
           "id" => _msg_id,
           # "url" => url,
           "user_name" => user_name,
           "comment_text" => comment_text,
           "blog_text" => blog_text
         } = _comment},
        state
      ) do
    # throw "whatever 1"
    case Pandex.html_to_plain(comment_text) do
      {:ok, comment_plain} ->
        # content =
        #   "type: weibo_comment\n" <>
        #     "id: #{msg_id}\n" <>
        #     "------\n" <> "#{user_name}评论了[Jolla微博](#{url}):\n" <> comment_plain
        blog_content =
          case Pandex.html_to_plain(blog_text) do
            {:error, _} ->
              ""

            {:ok, blog_plain} ->
              if String.length(blog_plain) > 10 do
                blog_plain
                |> String.slice(0..10)
                |> String.replace("[", "\\[")
                |> String.replace("]", "\\]")
                |> (fn s -> ":#{s}..." end).()
              else
                ":" <> blog_plain
              end
          end

        content =
          "#{user_name}评论了[Jolla微博#{blog_content}](https://weibo.com/jollaofficial):\n" <>
            comment_plain

        case Redix.command(:redis, ["SMEMBERS", "tg:sub:weibo_comment"]) do
          {:error, reason} = result ->
            Logger.error(
              "failed to execute redis LRANGE tg:sub:weibo_comment: #{inspect(reason)}"
            )

            result

          {:ok, chat_id_strs} ->
            ok_count =
              chat_id_strs
              |> Enum.map(&String.to_integer/1)
              |> Enum.map(fn chat_id ->
                JollaCNBot.API.Telegram.send_message(chat_id, content,
                  parse_mode: "Markdown",
                  disable_web_page_preview: true
                )
              end)
              |> Enum.count(fn
                {:ok, _} -> true
                _ -> false
              end)

            total_count = length(chat_id_strs)

            if total_count > 0 do
              if total_count == ok_count do
                Logger.info("telegram push_weibo_comment #{ok_count}/#{total_count}")
              else
                Logger.warn("telegram push_weibo_comment #{ok_count}/#{total_count}")
              end
            end
        end

      {:error, reason} = result ->
        Logger.error("failed to strip html from #{comment_text}: #{inspect(reason)}")
        result
    end

    # Logger.warn("fake receive, pub to telegram: #{user_name} / #{comment_text}")
    {:noreply, state}
  end

  def handle_cast(
        {:push_weibo_comment, comment},
        state
      ) do
    Logger.error("telegram bot worker failed to understand weibo comment #{inspect(comment)}")
    # throw "whatever 2"
    {:noreply, state}
  end

  def handle_info(:get_updates, state) do
    start_time = :os.system_time(:milli_seconds)
    Logger.debug("telegram bot get updates starts")

    case JollaCNBot.API.Telegram.get_updates() do
      {:error, _} = result ->
        result

      {:ok, updates} ->
        result =
          Enum.map(updates, fn
            %{"message" => %{"chat" => %{"id" => chat_id}, "text" => "/sub" <> _}} ->
              {:reply, result, _new_state} =
                handle_call({:sub_weibo_comment, chat_id}, self(), state)

              result

            _ ->
              {:ok, :skip}
          end)

        {:ok, result}
    end

    cost_seconds = (:os.system_time(:milli_seconds) - start_time) / 1000
    Logger.info("telegram bot get updates ends in #{cost_seconds} seconds")
    get_updates_loop()
    {:noreply, state}
  end

  def push_weibo_comment(comment) do
    # Logger.debug("genserver push_weibo_comment: #{inspect(comment)}")
    # Logger.debug("genserver push_weibo_comment to #{__MODULE__}")
    GenServer.cast(__MODULE__, {:push_weibo_comment, comment})
  end

  def sub_weibo_comment(chat_id) do
    # Logger.debug("genserver push_weibo_comment: #{inspect(comment)}")
    # Logger.debug("genserver push_weibo_comment to #{__MODULE__}")
    GenServer.call(__MODULE__, {:sub_weibo_comment, chat_id})
  end

  defp get_updates_loop() do
    :jollacn_bot
    |> Application.fetch_env!(:telegram_bot)
    |> Keyword.fetch!(:get_updates_interval)
    |> get_updates_loop()
  end

  defp get_updates_loop(interval, ignore_config \\ nil) do
    actual_do_it = if ignore_config == nil do
      config = :jollacn_bot
        |> Application.fetch_env!(:telegram_bot)
        |> Keyword.fetch!(:notice_mode)
      config == :pull
    else
      ignore_config
    end
    if actual_do_it do
      Logger.debug(
        "JollaCNBot.TelegramBot.Worker:get_updates will work in #{interval / 1000} seconds"
      )

      Process.send_after(self(), :get_updates, interval)
    end
  end
end
