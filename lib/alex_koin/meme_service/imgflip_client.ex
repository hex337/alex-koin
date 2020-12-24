defmodule Meme do
  @derive [Poison.Encoder]
  defstruct [:id, :name, :url, :width, :height, :box_count]
end

defmodule MemeResponseBody do
  @derive [Poison.Encoder]
  defstruct [:success, data: %{memes: %Meme{}}]
  #Decoding with the above syntax also does not work, which is a shame.
end

defmodule CaptionResponse do
  @derive [Poison.Encoder]
  defstruct [:success, data: %{url: String, page_url: String, error_message: String}]
end

defmodule ImgFlipClient do
  @moduledoc """
    Allows for fetching meme templates and captioning them
  """

  @url "https://api.imgflip.com/"

  def fetch_template_list do
    case HTTPoison.get(@url <> "get_memes") do
      {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} ->
        decrypted = Poison.decode!(resp_body)
        Enum.map(decrypted["data"]["memes"], fn data ->
          IO.inspect(data)
          Poison.decode!(Poison.encode!(data), as: %Meme{})
        end)
    end
  end

  def caption_image(template_id, text_top, text_bottom) do
    post_params = build_caption_post_params(template_id, text_top, text_bottom)
    case HTTPoison.post(@url <> "caption_image?" <> post_params, "") do
      {:ok, %HTTPoison.Response{status_code: 200, body: resp_body}} ->
        Poison.decode!(resp_body, as: %CaptionResponse{})
    end
  end

  def caption_image(_template_id, _boxes) do
    ## Some meme templates have more than two placements for text. We can implement that too, if we want.
  end

  def build_caption_post_params(template_id, text_top, text_bottom) do
    %{
      template_id: template_id, username: System.get_env("IMGFLIP_USER"), password: System.get_env("IMGFLIP_PASS"),
      text0: text_top, text1: text_bottom
    }
    |> URI.encode_query
  end
end
