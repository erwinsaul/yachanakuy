defmodule Yachanakuy.Events.EventInfo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "event_info" do
    field :titulo, :string
    field :descripcion, :string
    field :estado, :string, default: "activo"
    field :imagen, :string
    field :activo, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event_info, attrs) do
    event_info
    |> cast(attrs, [:titulo, :descripcion, :estado, :imagen, :activo])
    |> validate_required([:titulo])
    |> validate_length(:titulo, min: 1, max: 200)
    |> validate_length(:descripcion, max: 1000)
    |> validate_inclusion(:estado, ["borrador", "publicado", "activo", "inactivo", "finalizado"])
    |> validate_length(:imagen, max: 300)
  end
end