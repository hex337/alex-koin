defmodule AlexKoin.Repo.Migrations.CreateWallets do
  use Ecto.Migration

  def change do
    create table(:wallets) do
      add :balance, :float
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:wallets, [:user_id])
  end
end
