defmodule AlexKoin.Account.User do
  use Ecto.Schema
  import Ecto.{ Changeset, Query }
  alias AlexKoin.Account.Wallet
  alias AlexKoin.Coins.Coin


  schema "users" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :slack_id, :string

    has_one :wallet, Wallet
    has_many :coins, Coin, foreign_key: :mined_by_id

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :slack_id])
    |> validate_required([:slack_id])
  end
end
