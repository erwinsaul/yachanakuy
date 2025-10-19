defmodule Yachanakuy.Repo.Migrations.CreateSettings do
  use Ecto.Migration

  def change do
    create table(:settings) do
      add :nombre, :string, null: false
      add :descripcion, :text
      add :fecha_inicio, :date
      add :fecha_fin, :date
      add :ubicacion, :string
      add :direccion_evento, :text
      add :logo, :string
      add :estado, :string, null: false
      add :inscripciones_abiertas, :boolean, default: false
      add :info_turismo, :text

      timestamps(type: :utc_datetime)
    end
  end
end
