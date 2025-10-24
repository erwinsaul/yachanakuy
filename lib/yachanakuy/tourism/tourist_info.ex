defmodule Yachanakuy.Tourism.TouristInfo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tourist_info" do
    field :titulo, :string
    field :descripcion, :string
    field :direccion, :string
    field :imagen, :string
    field :estado, :string, default: "activo"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tourist_info, attrs) do
    tourist_info
    |> cast(attrs, [:titulo, :descripcion, :direccion, :imagen, :estado])
    |> validate_required([:titulo])
    |> validate_length(:titulo, min: 1, max: 200)
    |> validate_length(:descripcion, max: 1000)
    |> validate_length(:direccion, max: 300)
    |> validate_length(:imagen, max: 300)
    |> validate_inclusion(:estado, ["borrador", "publicado", "activo", "inactivo", "finalizado"])
  end
end
