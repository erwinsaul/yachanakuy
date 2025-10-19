defmodule Yachanakuy.Program.Session do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sessions" do
    field :titulo, :string
    field :descripcion, :string
    field :fecha, :date
    field :hora_inicio, :time
    field :hora_fin, :time
    field :tipo, :string

    # Associations (speaker_id and room_id fields are created automatically by belongs_to)
    belongs_to :speaker, Yachanakuy.Program.Speaker
    belongs_to :room, Yachanakuy.Program.Room
    has_many :session_attendances, Yachanakuy.Deliveries.SessionAttendance

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(session, attrs) do
    session
    |> cast(attrs, [:titulo, :descripcion, :fecha, :hora_inicio, :hora_fin, :tipo, :speaker_id, :room_id])
    |> validate_required([:titulo, :fecha, :hora_inicio, :hora_fin, :tipo])
    |> validate_inclusion(:tipo, ["conferencia", "taller", "receso", "plenaria"])
    |> validate_length(:titulo, min: 1, max: 200)
    |> validate_length(:descripcion, max: 1000)
  end
end
