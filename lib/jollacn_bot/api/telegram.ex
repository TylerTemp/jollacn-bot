defmodule JollaCNBot.API.Telegram do
  require Logger

  @timeout 15_000

  defp get_url("/" <> sub_uri) do
    token = :jollacn_bot |> Application.fetch_env!(:telegram_bot) |> Keyword.fetch!(:token)
    "https://api.telegram.org/bot#{token}/#{sub_uri}"
  end

  def get_updates() do
    url = get_url("/getUpdates")
    proxy = :jollacn_bot |> Application.fetch_env!(:telegram_bot) |> Keyword.get(:proxy, {})

    case HTTPoison.get(url, [], proxy: proxy, timeout: @timeout, recv_timeout: @timeout) do
      {:error, %HTTPoison.Error{reason: :timeout}} = result ->
        Logger.error("failed to get #{url}: timeout")
        result

      {:error, reason} = result ->
        Logger.error("failed to get #{url}: #{inspect(reason)}")
        result

      {:ok, %{status_code: status_code, body: body}} when status_code >= 400 ->
        Logger.error("failed to get #{url}: status #{400}, #{body}")
        {:error, status_code}

      {:ok, %{body: body}} ->
        case Jason.decode!(body) do
          %{"ok" => true, "result" => updates} ->
            {:ok, updates}

          body ->
            Logger.error("failed to parse #{url}: #{inspect(body)}")
            {:error, body}
        end
    end
  end

  def send_message(chat_id, text, options \\ []) do
    url = get_url("/sendMessage")

    body =
      options
      |> Map.new()
      |> Map.merge(%{
        chat_id: chat_id,
        text: text
      })
      |> Jason.encode!()

    proxy = :jollacn_bot |> Application.fetch_env!(:telegram_bot) |> Keyword.get(:proxy, {})

    headers = [
      {"Connection", "Close"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(url, body, headers,
           proxy: proxy,
           timeout: @timeout,
           recv_timeout: @timeout
         ) do
      {:error, %HTTPoison.Error{reason: :timeout}} = result ->
        Logger.error("failed to post #{url} #{body}: timeout")
        result

      {:error, reason} = result ->
        Logger.error("failed to post #{url} #{body}: #{inspect(reason)}")
        result

      {:ok, %{status_code: status_code, body: body}} when status_code >= 400 ->
        Logger.error("failed to post #{url} #{body}: status #{400}, #{body}")
        {:error, status_code}

      {:ok, %{body: body}} ->
        case Jason.decode!(body) do
          %{"ok" => true, "result" => result} ->
            {:ok, result}

          body ->
            Logger.error("failed to parse #{url}: #{inspect(body)}")
            {:error, body}
        end
    end
  end
end
