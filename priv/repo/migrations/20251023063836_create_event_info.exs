defmodule Yachanakuy.Repo.Migrations.CreateEventInfo do
  use Ecto.Migration

  def change do
    create table(:event_info) do
      add :titulo, :string, null: false, size: 200
      add :descripcion, :text
      add :estado, :string, default: "activo"
      add :imagen, :string, size: 300
      add :activo, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create index(:event_info, [:estado])
    create index(:event_info, [:activo])
  end
end
