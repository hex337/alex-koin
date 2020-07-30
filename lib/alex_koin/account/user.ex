defmodule AlexKoin.Account.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias AlexKoin.Account.Wallet
  alias AlexKoin.Coins.Coin

  @admin_id Application.get_env(:alex_koin, :admin_id)
  @koin_lord_ids Application.get_env(:alex_koin, :koin_lord_ids)

  schema "users" do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:slack_id, :string)

    has_one(:wallet, Wallet)
    has_many(:coins, Coin, foreign_key: :mined_by_id)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :slack_id])
    |> validate_required([:slack_id])
  end

  def koin_lord?(%{slack_id: slack_id}) do
    slack_id in @koin_lord_ids
  end

  def admin?(%{slack_id: slack_id}) do
    slack_id == @admin_id
  end
end
