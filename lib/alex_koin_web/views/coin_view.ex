defmodule AlexKoinWeb.CoinView do
  use AlexKoinWeb, :view
  alias AlexKoinWeb.CoinView

  def render("index.json", %{coins: coins}) do
    %{data: render_many(coins, CoinView, "coin.json")}
  end

  def render("show.json", %{coin: coin}) do
    %{data: render_one(coin, CoinView, "coin.json")}
  end

  def render("coin.json", %{coin: coin}) do
    %{id: coin.id, hash: coin.hash, origin: coin.origin}
  end
end
