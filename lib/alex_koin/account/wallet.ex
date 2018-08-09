defmodule AlexKoin.Account.Wallet do
  use Ecto.Schema
  import Ecto.Changeset


  schema "wallets" do
    field :balance, :float
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(wallet, attrs) do
    wallet
    |> cast(attrs, [:balance])
    |> validate_required([:balance])
  end
end
