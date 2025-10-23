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
    |> validate_email()
    |> validate_length(:nombre_completo, min: 1, max: 200)
    |> validate_length(:institucion, max: 100)
    |> validate_length(:email, max: 100)
    |> validate_length(:biografia, max: 1000)
    |> validate_url_or_upload_format(:foto)
  end

  # Validar email solo si está presente
  defp validate_email(changeset) do
    case get_change(changeset, :email) do
      nil -> changeset
      "" -> changeset
      _email -> validate_format(changeset, :email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: "must have the @ sign and no spaces")
    end
  end

  # Validación personalizada para permitir URL o rutas locales de archivo
  defp validate_url_or_upload_format(changeset, field) do
    case get_change(changeset, field) do
      nil -> changeset
      value -> 
        if is_valid_url?(value) or is_local_path?(value) or is_uploading_file?(value) do
          changeset
        else
          add_error(changeset, field, "must be a valid URL, local path, or file upload")
        end
    end
  end

  defp is_valid_url?(value) when is_binary(value) do
    String.starts_with?(value, ["http://", "https://"])
  end
  defp is_valid_url?(_), do: false

  defp is_local_path?(value) when is_binary(value) do
    String.starts_with?(value, ["uploads/", "/uploads/"])
  end
  defp is_local_path?(_), do: false

  defp is_uploading_file?(_value), do: true  # Asumimos que si llega aquí en contexto de upload, es válido temporalmente
end
