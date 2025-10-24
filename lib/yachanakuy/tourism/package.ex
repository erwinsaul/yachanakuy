defmodule Yachanakuy.Tourism.Package do
  use Ecto.Schema
  import Ecto.Changeset

  schema "packages" do
    field :titulo, :string
    field :descripcion, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(package, attrs) do
    package
    |> cast(attrs, [:titulo, :descripcion])
    |> validate_required([:titulo])
    |> validate_length(:titulo, min: 1, max: 200)
    |> validate_length(:descripcion, max: 1000)
  end
end
