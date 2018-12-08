defmodule JollaCNBot.TelegramBot.Router do
  use Plug.Router

  require Logger

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "PONG")
  end

  post "/webhook" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    Logger.info("get webhook #{body}")

    {deal_result, {chat_id, message_id, reply_message}} =
      case Jason.decode(body) do
        {:error, reason} ->
          Logger.warn("failed to parse webhook request #{body}")
          {:error, {nil, nil, "bong! 服务器解析失败了：#{inspect(reason)}"}}

        # sub
        {:ok,
         %{
           "message" => %{
             "message_id" => message_id,
             "chat" => %{"id" => chat_id},
             "text" => "/sub" <> _
           }
         }} ->
          Logger.debug("try to sub #{chat_id}")

          case JollaCNBot.TelegramBot.Worker.sub_weibo_comment(chat_id) do
            {:error, reason} ->
              {:ok, {chat_id, message_id, "bong! 服务器炸了：#{reason}"}}

            {:ok, :exist} ->
              {:ok, {chat_id, message_id, "已经订阅过了，你想整啥？"}}

            {:ok, _chat_id} ->
              {:ok, {chat_id, message_id, "订阅成功"}}
          end

        {:ok,
         %{
           "message" => %{
             "message_id" => message_id,
             "chat" => %{"id" => chat_id},
             "text" => content
           }
         }} ->
           # {:ok, {chat_id, message_id, "说啥，听不懂：#{content}"}}
          {:ok, {chat_id, message_id, ""}}

        {:ok, %{"message" => %{"chat" => %{"id" => chat_id}}}} ->
          # {:ok, {chat_id, nil, "说啥，听不懂"}}
          {:ok, {chat_id, nil, ""}}

        {:ok, req_body} ->
          Logger.error("failed to understand request #{inspect(req_body)}")
          {:ok, {nil, nil, ""}}
      end

    if chat_id != nil && reply_message != "" do
      options =
        if message_id == nil do
          []
        else
          [reply_to_message_id: message_id]
        end

      Task.start(fn -> JollaCNBot.API.Telegram.send_message(chat_id, reply_message, options) end)
    end

    if deal_result == :ok do
      conn
      |> put_resp_header("Content-Type", "text/plain")
      |> send_resp(200, "True")
    else
      conn
      |> put_resp_header("Content-Type", "text/plain")
      |> send_resp(500, "False")
    end
  end

  match _ do
    conn
    |> put_resp_header("Content-Type", "application/json")
    |> send_resp(
      404,
      Jason.encode!(%{
        "message" => "request #{conn.method} #{conn.request_path} not found or allowed"
      })
    )
  end
end
