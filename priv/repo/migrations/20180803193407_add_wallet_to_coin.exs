defmodule AlexKoin.Repo.Migrations.AddWalletToCoin do
  use Ecto.Migration

  def change do
    alter table(:coins) do
      add :wallet_id, references(:wallets)
    end
  end
end
