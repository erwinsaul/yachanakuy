defmodule Yachanakuy.Program.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :nombre, :string
    field :capacidad, :integer
    field :ubicacion, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:nombre, :capacidad, :ubicacion])
    |> validate_required([:nombre])
    |> validate_number(:capacidad, greater_than: 0, message: "must be greater than 0")
    |> validate_length(:nombre, min: 1, max: 100)
    |> validate_length(:ubicacion, max: 200)
  end
end
