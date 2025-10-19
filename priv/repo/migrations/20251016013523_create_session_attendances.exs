defmodule Yachanakuy.Repo.Migrations.CreateSessionAttendances do
  use Ecto.Migration

  def change do
    create table(:session_attendances) do
      add :fecha_escaneo, :utc_datetime
      add :attendee_id, references(:attendees, on_delete: :delete_all)
      add :session_id, references(:sessions, on_delete: :delete_all)
      add :escaneado_por, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:session_attendances, [:attendee_id, :session_id], name: :session_attendances_attendee_id_session_id_index)
    create index(:session_attendances, [:attendee_id])
    create index(:session_attendances, [:session_id])
    create index(:session_attendances, [:escaneado_por])
  end
end
