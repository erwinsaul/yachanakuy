defmodule Yachanakuy.Repo.Migrations.CreateModuleConfigurations do
  use Ecto.Migration

  def change do
    create table(:module_configurations) do
      add :module_name, :string
      add :enabled, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:module_configurations, [:module_name])
  end
end
