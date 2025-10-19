defmodule Yachanakuy.Repo.Migrations.CreateCommissionOperators do
  use Ecto.Migration

  def change do
    create table(:commission_operators) do
      add :commission_id, references(:commissions, on_delete: :delete_all)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:commission_operators, [:commission_id, :user_id], name: :commission_operators_commission_id_user_id_index)

    create index(:commission_operators, [:commission_id])
    create index(:commission_operators, [:user_id])
  end
end
