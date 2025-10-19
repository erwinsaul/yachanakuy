defmodule Yachanakuy.Repo.Migrations.CreateEmailLogs do
  use Ecto.Migration

  def change do
    create table(:email_logs) do
      add :tipo_email, :string
      add :destinatario, :string
      add :fecha_envio, :utc_datetime
      add :estado, :string
      add :attendee_id, references(:attendees, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:email_logs, [:attendee_id])
    create index(:email_logs, [:tipo_email])
    create index(:email_logs, [:fecha_envio])
  end
end
