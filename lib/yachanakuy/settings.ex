defmodule Yachanakuy.Settings do
  @moduledoc """
  The Settings context.
  """

  import Ecto.Query, warn: false
  alias Yachanakuy.Repo

  alias Yachanakuy.Settings.ModuleConfiguration

  @doc """
  Returns the list of module_configurations.

  ## Examples

      iex> list_module_configurations()
      [%ModuleConfiguration{}, ...]

  """
  def list_module_configurations do
    Repo.all(ModuleConfiguration)
  end

  @doc """
  Gets a single module_configuration.

  Raises `Ecto.NoResultsError` if the Module configuration does not exist.

  ## Examples

      iex> get_module_configuration!(123)
      %ModuleConfiguration{}

      iex> get_module_configuration!(456)
      ** (Ecto.NoResultsError)

  """
  def get_module_configuration!(id) do
    Repo.get!(ModuleConfiguration, id)
  end

  @doc """
  Gets a single module_configuration by ID.

  Returns nil if the Module configuration does not exist.

  ## Examples

      iex> get_module_configuration(123)
      %ModuleConfiguration{}

      iex> get_module_configuration(456)
      nil

  """
  def get_module_configuration(id) do
    Repo.get(ModuleConfiguration, id)
  end

  @doc """
  Creates a module_configuration.

  ## Examples

      iex> create_module_configuration(%{field: value})
      {:ok, %ModuleConfiguration{}}

      iex> create_module_configuration(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_module_configuration(attrs) do
    %ModuleConfiguration{}
    |> ModuleConfiguration.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a module_configuration.

  ## Examples

      iex> update_module_configuration(module_configuration, %{field: new_value})
      {:ok, %ModuleConfiguration{}}

      iex> update_module_configuration(module_configuration, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_module_configuration(%ModuleConfiguration{} = module_configuration, attrs) do
    module_configuration
    |> ModuleConfiguration.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a module_configuration.

  ## Examples

      iex> delete_module_configuration(module_configuration)
      {:ok, %ModuleConfiguration{}}

      iex> delete_module_configuration(module_configuration)
      {:error, %Ecto.Changeset{}}

  """
  def delete_module_configuration(%ModuleConfiguration{} = module_configuration) do
    Repo.delete(module_configuration)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking module_configuration changes.

  ## Examples

      iex> change_module_configuration(module_configuration)
      %Ecto.Changeset{data: %ModuleConfiguration{}}

  """
  def change_module_configuration(%ModuleConfiguration{} = module_configuration, attrs \\ %{}) do
    ModuleConfiguration.changeset(module_configuration, attrs)
  end

  @doc """
  Gets a module configuration by its name.
  
  Returns nil if not found.
  """
  def get_module_configuration_by_name(name) do
    Repo.get_by(ModuleConfiguration, module_name: name)
  end

  @doc """
  Gets the enabled state of a module by its name.
  
  Returns true if enabled or if not configured.
  """
  def is_module_enabled(name) do
    case get_module_configuration_by_name(name) do
      nil -> true  # Default to enabled if not configured
      config -> config.enabled
    end
  end
end
