defmodule JollaCNBot.Publish.WeiBo.MobileAPI do
  require Logger

  @entrance_url "https://m.weibo.cn/api/container/getIndex?containerid=1076032805310855"
  @user_agent "Mozilla/5.0 (compatible; Bingbot/2.0; +http://www.bing.com/bingbot.htm)"

  def run() do
    case extract_blogs(get_main()) do
      result = {:error, _reason} ->
        result

      {:ok, blogs} ->
        blog_with_comment_result =
          Enum.map(blogs, fn blog ->
            case extract_comments(get_comments(blog)) do
              {:error, _reason} ->
                %{"comments" => [], "comments_ok" => false}

              {:ok, comments} ->
                Map.merge(blog, %{"comments" => comments, "comments_ok" => true})
            end
          end)

        {:ok, blog_with_comment_result}
    end
  end

  def get_main() do
    Logger.debug("getting url #{@entrance_url}")

    case HTTPoison.get(@entrance_url,
           "User-Agent": @user_agent,
           Connection: "Close"
         ) do
      {:ok, %{status_code: status_code, body: body}}
      when status_code >= 200 and status_code < 400 ->
        result = Jason.decode!(body)
        {:ok, result}

      {:ok, %{status_code: status_code, body: body}} ->
        {:error, "#{status_code}|#{@entrance_url}|#{body}"}

      result = {:error, _reason} ->
        result
    end
  end

  def extract_blogs(
        {:ok,
         %{
           "data" => %{
             "cards" => cards
           }
         }}
      ) do
    result =
      Enum.map(cards, fn
        %{"mblog" => %{"text" => text, "id" => id, "mid" => mid}} ->
          %{"ok" => true, "text" => text, "id" => id, "mid" => mid}

        card ->
          Logger.warn("unable to parse card #{inspect(card)}")
          %{"ok" => false}
      end)

    {:ok, result}
  end

  def extract_blogs({:ok, result}) do
    Logger.error("failed to extract cards from #{inspect(result)}")
    {:error, "failed to parse"}
  end

  def extract_blogs(result = {:error, _result}) do
    result
  end

  def get_comments(%{"ok" => true, "id" => id, "mid" => mid}) do
    url = "https://m.weibo.cn/comments/hotflow?id=#{id}&mid=#{mid}&max_id_type=0"

    Logger.debug("getting url #{url}")

    case HTTPoison.get(url,
           "User-Agent": @user_agent,
           Connection: "Close"
         ) do
      {:ok, %{status_code: status_code, body: body}}
      when status_code >= 200 and status_code < 400 ->
        result = Jason.decode!(body)
        {:ok, result}

      {:ok, %{status_code: status_code, body: body}} ->
        {:error, "#{status_code}|#{url}|#{body}"}

      result = {:error, _reason} ->
        result
    end
  end

  def get_comments(%{"ok" => false}) do
    {:error, "ok=false"}
  end

  def get_comments(instruct) do
    Logger.warn("unable to parse for get_comment #{inspect(instruct)}")
    {:error, "failed to parse"}
  end

  def extract_comments({:ok, %{"data" => %{"data" => comment_datas}}}) do
    result =
      Enum.map(comment_datas, fn
        %{"text" => text, "id" => id, "user" => %{"id" => user_id, "screen_name" => user_name}} ->
          %{
            "ok" => true,
            "text" => text,
            "id" => id,
            "user_id" => user_id,
            "user_name" => user_name
          }

        struct ->
          Logger.warn("unable to extract comment from #{inspect(struct)}")
          %{"ok" => false}
      end)

    {:ok, result}
  end
end
