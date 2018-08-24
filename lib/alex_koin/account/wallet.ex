defmodule AlexKoin.Account.Wallet do
  use Ecto.Schema
  import Ecto.Changeset
  alias AlexKoin.Account.User


  schema "wallets" do
    field :balance, :float

    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:balance, :user_id])
    |> validate_required([:balance, :user_id])
  end
end
