defmodule AlexKoin.Repo.Migrations.AddCreatorToKoin do
  use Ecto.Migration

  def change do
    alter table("coins") do
      add_if_not_exists :created_by_user_id, :integer, default: nil
    end
  end
end
