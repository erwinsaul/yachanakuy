defmodule Yachanakuy.Repo.Migrations.CreateTouristInfo do
  use Ecto.Migration

  def change do
    create table(:tourist_info) do
      add :titulo, :string
      add :descripcion, :text
      add :direccion, :string
      add :imagen, :string
      add :estado, :string, default: "activo"

      timestamps(type: :utc_datetime)
    end
  end
end
