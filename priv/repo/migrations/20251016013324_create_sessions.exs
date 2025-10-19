defmodule Yachanakuy.Repo.Migrations.CreateSessions do
  use Ecto.Migration

  def change do
    create table(:sessions) do
      add :titulo, :string
      add :descripcion, :text
      add :fecha, :date
      add :hora_inicio, :time
      add :hora_fin, :time
      add :tipo, :string
      add :speaker_id, references(:speakers, on_delete: :nilify_all)
      add :room_id, references(:rooms, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:sessions, [:speaker_id])
    create index(:sessions, [:room_id])
    create index(:sessions, [:fecha])
  end
end
