defmodule Yachanakuy.Events.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "settings" do
    field :nombre, :string
    field :descripcion, :string
    field :fecha_inicio, :date
    field :fecha_fin, :date
    field :ubicacion, :string
    field :direccion_evento, :string
    field :logo, :string
    field :estado, :string
    field :inscripciones_abiertas, :boolean, default: false
    field :info_turismo, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(settings, attrs) do
    # Normalizar los atributos para evitar claves mezcladas
    normalized_attrs = normalize_attrs(attrs)
    
    settings
    |> cast(normalized_attrs, [:nombre, :descripcion, :fecha_inicio, :fecha_fin, :ubicacion, :direccion_evento, :logo, :estado, :inscripciones_abiertas, :info_turismo])
    |> validate_required([:nombre, :estado])
    |> validate_inclusion(:estado, ["borrador", "publicado", "activo", "finalizado"])
    |> validate_length(:nombre, min: 1, max: 200)
    |> validate_length(:ubicacion, max: 100)
    |> validate_length(:direccion_evento, max: 300)
    |> validate_length(:logo, max: 300)
  end

  defp normalize_attrs(attrs) do
    # Convertir todas las claves a átomos y procesar los valores apropiadamente
    attrs
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      atom_key = case k do
        k when is_binary(k) -> String.to_atom(k)
        k when is_atom(k) -> k
        _ -> k
      end
      
      # Procesar valores especiales
      processed_value = case {atom_key, v} do
        {:inscripciones_abiertas, "true"} -> true
        {:inscripciones_abiertas, "false"} -> false
        {:estado, val} when is_binary(val) -> 
          # Convertir a minúsculas y verificar que sea un valor válido
          estado_lower = String.downcase(val)
          if estado_lower in ["borrador", "publicado", "activo", "finalizado"] do
            estado_lower
          else
            # Si no es válido, usar el valor original para que se capture en la validación
            val
          end
        {_, val} when is_binary(val) and val == "" -> nil
        {_, val} -> val
      end
      
      Map.put(acc, atom_key, processed_value)
    end)
  end

  # Additional changeset for singleton settings
  def singleton_changeset(settings, attrs) do
    settings
    |> changeset(attrs)
    |> validate_singleton()
  end

  defp validate_singleton(changeset) do
    # We only want one settings record ever, so we validate that the id is typically 1
    # This is handled at the database level with a constraint, but we can add application-level validation too
    if get_field(changeset, :id) && get_field(changeset, :id) != 1 do
      add_error(changeset, :id, "Only one settings record is allowed")
    else
      changeset
    end
  end
end
