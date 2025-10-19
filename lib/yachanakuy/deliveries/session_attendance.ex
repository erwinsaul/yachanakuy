defmodule Yachanakuy.Deliveries.SessionAttendance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "session_attendances" do
    field :fecha_escaneo, :utc_datetime

    # Associations (attendee_id, session_id and escaneado_por fields are created automatically by belongs_to)
    belongs_to :attendee, Yachanakuy.Registration.Attendee
    belongs_to :session, Yachanakuy.Program.Session
    belongs_to :scanned_by, Yachanakuy.Accounts.User, foreign_key: :escaneado_por

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(session_attendance, attrs) do
    session_attendance
    |> cast(attrs, [:fecha_escaneo, :attendee_id, :session_id, :escaneado_por])
    |> validate_required([:fecha_escaneo, :attendee_id, :session_id, :escaneado_por])
    |> unique_constraint([:attendee_id, :session_id], 
      name: :session_attendances_attendee_id_session_id_index,
      message: "Este participante ya registró asistencia a esta sesión"
    )
    |> validate_attendee_approved()
  end

  defp validate_attendee_approved(changeset) do
    # Validate that the attendee is approved before allowing attendance registration
    attendee_id = get_field(changeset, :attendee_id)
    
    if attendee_id do
      import Ecto.Query
      alias Yachanakuy.Repo
      alias Yachanakuy.Registration.Attendee
      
      query = from a in Attendee,
        where: a.id == ^attendee_id,
        select: a.estado
      
      case Repo.one(query) do
        "aprobado" -> 
          changeset
        _ -> 
          add_error(changeset, :attendee_id, "Solo pueden registrar asistencia participantes aprobados")
      end
    else
      changeset
    end
  end
end
