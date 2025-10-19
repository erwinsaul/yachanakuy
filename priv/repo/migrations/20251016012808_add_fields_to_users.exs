defmodule Yachanakuy.Repo.Migrations.AddFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :nombre_completo, :string, null: false
      add :rol, :string, null: false
      add :activo, :boolean, default: true
    end
  end
end
