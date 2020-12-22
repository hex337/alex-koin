defmodule Meme do 
  @derive [Poison.Encoder]
  defstruct [:id, :name, :url, :width, :height, :box_count]
end

defmodule ImgFlipClient do 
  @moduledoc """
    Allows for fetching meme templates and captioning them
  """

  @url "https://api.imgflip.com/"

  def fetch_template_list do
    case HTTPoison.get(@url <> "get_memes") do
      # Below would have been cool to try out but body is not actually decrypted yet
      # {:ok, %HTTPoison.Response{status_code: 200, body: %{"success" => true} = resp_body}} ->
      {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} ->
        decrypted = Poison.decode!(resp_body)
        Enum.map(decrypted["data"]["memes"], fn data -> 
          IO.inspect(data)
          # This is just silly, I'm re serializing to turn it into an object :|
          Poison.decode!(Poison.encode!(data), as: %Meme{})
        end)
    end
  end
end
