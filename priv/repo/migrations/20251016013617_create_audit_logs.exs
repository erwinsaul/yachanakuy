defmodule Yachanakuy.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :accion, :string
      add :tipo_recurso, :string
      add :id_recurso, :integer
      add :cambios, :text
      add :fecha_accion, :utc_datetime
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:audit_logs, [:user_id])
    create index(:audit_logs, [:accion])
    create index(:audit_logs, [:fecha_accion])
  end
end
