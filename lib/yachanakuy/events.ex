defmodule Yachanakuy.Events do
  @moduledoc """
  The Events context.
  """
  import Ecto.Query, warn: false
  alias Yachanakuy.Repo

  alias Yachanakuy.Events.Settings

  def get_congress_settings do
    case Repo.all(Settings) do
      [settings | _] -> settings
      [] -> nil
    end
  end

  def get_congress_settings_with_error! do
    Repo.one!(Settings)
  end

  def create_settings(attrs \\ %{}) do
    # Ensure we only ever have one settings record
    case get_congress_settings() do
      nil -> 
        %Settings{}
        |> Settings.changeset(attrs)
        |> Repo.insert()
      _ -> 
        {:error, :singleton_exists}
    end
  end

  def update_settings(%Settings{} = settings, attrs) do
    try do
      # Obtener el registro actual y aplicar cambios
      current_settings = Repo.get!(Settings, settings.id)
      
      # Verificar qué estado está intentando ser actualizado
      nuevo_estado = Map.get(attrs, :estado) || Map.get(attrs, "estado")
      IO.inspect(nuevo_estado, label: "Intentando actualizar estado a")
      
      # Aplicar changeset con los atributos dados
      changeset = Settings.changeset(current_settings, attrs)
      
      # Verificar si hay errores de estado
      if changeset.errors[:estado] do
        IO.inspect(changeset.errors[:estado], label: "Error de estado")
      end
      
      case Repo.update(changeset) do
        {:ok, updated_settings} ->
          IO.inspect(updated_settings.estado, label: "Estado después de la actualización")
          {:ok, updated_settings}
        {:error, changeset} ->
          IO.inspect(changeset.errors, label: "Errores del changeset")
          {:error, changeset}
      end
    rescue
      e ->
        # Registrar el error para diagnóstico pero no dejar que cause timeouts
        IO.inspect(e, label: "Error en update_settings")
        {:error, :unexpected_error}
    end
  end

  def delete_settings(%Settings{} = settings) do
    Repo.delete(settings)
  end

  def change_settings(%Settings{} = settings, attrs \\ %{}) do
    Settings.changeset(settings, attrs)
  end

  alias Yachanakuy.Events.AttendeeCategory

  def list_attendee_categories do
    Repo.all(AttendeeCategory)
  end

  def get_attendee_category!(id) do
    Repo.get!(AttendeeCategory, id)
  end

  def create_attendee_category(attrs \\ %{}) do
    %AttendeeCategory{}
    |> AttendeeCategory.changeset(attrs)
    |> Repo.insert()
  end

  def update_attendee_category(%AttendeeCategory{} = attendee_category, attrs) do
    attendee_category
    |> AttendeeCategory.changeset(attrs)
    |> Repo.update()
  end

  def delete_attendee_category(%AttendeeCategory{} = attendee_category) do
    Repo.delete(attendee_category)
  end

  def change_attendee_category(%AttendeeCategory{} = attendee_category, attrs \\ %{}) do
    AttendeeCategory.changeset(attendee_category, attrs)
  end
end
