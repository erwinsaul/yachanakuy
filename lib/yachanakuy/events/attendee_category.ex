defmodule Yachanakuy.Events.AttendeeCategory do
  use Ecto.Schema
  import Ecto.Changeset

  schema "attendee_categories" do
    field :nombre, :string
    field :codigo, :string
    field :precio, :decimal
    field :color, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attendee_category, attrs) do
    attendee_category
    |> cast(attrs, [:nombre, :codigo, :precio, :color])
    |> validate_required([:nombre, :codigo, :precio])
    |> unique_constraint(:codigo)
    |> validate_length(:nombre, min: 1, max: 50)
    |> validate_length(:codigo, min: 1, max: 10)
    |> validate_number(:precio, greater_than_or_equal_to: 0, message: "must be greater than or equal to 0")
    |> validate_format(:color, ~r/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/, message: "must be a valid hex color code")
  end
end
