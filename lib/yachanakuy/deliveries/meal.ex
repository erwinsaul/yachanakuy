defmodule Yachanakuy.Deliveries.Meal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meals" do
    field :nombre, :string
    field :tipo, :string
    field :fecha, :date
    field :hora_desde, :time
    field :hora_hasta, :time

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meal, attrs) do
    meal
    |> cast(attrs, [:nombre, :tipo, :fecha, :hora_desde, :hora_hasta])
    |> validate_required([:nombre, :tipo, :fecha])
    |> validate_inclusion(:tipo, ["desayuno", "almuerzo", "snack", "cena"])
    |> validate_length(:nombre, min: 1, max: 100)
  end
end
