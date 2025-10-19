defmodule Yachanakuy.Deliveries.MealDelivery do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meal_deliveries" do
    field :fecha_entrega, :utc_datetime

    # Associations (attendee_id, meal_id and entregado_por fields are created automatically by belongs_to)
    belongs_to :attendee, Yachanakuy.Registration.Attendee
    belongs_to :meal, Yachanakuy.Deliveries.Meal
    belongs_to :delivered_by, Yachanakuy.Accounts.User, foreign_key: :entregado_por

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meal_delivery, attrs) do
    meal_delivery
    |> cast(attrs, [:fecha_entrega, :attendee_id, :meal_id, :entregado_por])
    |> validate_required([:fecha_entrega, :attendee_id, :meal_id, :entregado_por])
    |> unique_constraint([:attendee_id, :meal_id], 
      name: :meal_deliveries_attendee_id_meal_id_index,
      message: "Este participante ya recibió este refrigerio"
    )
    |> validate_attendee_approved()
  end

  defp validate_attendee_approved(changeset) do
    # Validate that the attendee is approved before allowing delivery
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
          add_error(changeset, :attendee_id, "Solo se pueden entregar refrigerios a participantes aprobados")
      end
    else
      changeset
    end
  end
end
