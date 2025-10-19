defmodule Yachanakuy.Program.Speaker do
  use Ecto.Schema
  import Ecto.Changeset

  schema "speakers" do
    field :nombre_completo, :string
    field :biografia, :string
    field :institucion, :string
    field :foto, :string
    field :email, :string

    has_many :sessions, Yachanakuy.Program.Session

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(speaker, attrs) do
    speaker
    |> cast(attrs, [:nombre_completo, :biografia, :institucion, :foto, :email])
    |> validate_required([:nombre_completo])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:nombre_completo, min: 1, max: 200)
    |> validate_length(:institucion, max: 100)
    |> validate_length(:email, max: 100)
    |> validate_length(:biografia, max: 1000)
  end
end
