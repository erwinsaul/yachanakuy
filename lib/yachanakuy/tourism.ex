defmodule Yachanakuy.Tourism do
  @moduledoc """
  The Tourism context.
  """

  import Ecto.Query, warn: false
  alias Yachanakuy.Repo

  alias Yachanakuy.Tourism.TouristInfo

  @doc """
  Returns the list of tourist_info.

  ## Examples

      iex> list_tourist_info()
      [%TouristInfo{}, ...]

  """
  def list_tourist_info do
    Repo.all(TouristInfo)
  end

  @doc """
  Gets a single tourist_info.

  Raises `Ecto.NoResultsError` if the Tourist info does not exist.

  ## Examples

      iex> get_tourist_info!(123)
      %TouristInfo{}

      iex> get_tourist_info!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tourist_info!(id) do
    Repo.get!(TouristInfo, id)
  end

  @doc """
  Gets a single tourist_info by ID.

  Returns nil if the Tourist info does not exist.

  ## Examples

      iex> get_tourist_info(123)
      %TouristInfo{}

      iex> get_tourist_info(456)
      nil

  """
  def get_tourist_info(id) do
    Repo.get(TouristInfo, id)
  end

  @doc """
  Creates a tourist_info.

  ## Examples

      iex> create_tourist_info(%{field: value})
      {:ok, %TouristInfo{}}

      iex> create_tourist_info(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tourist_info(attrs) do
    %TouristInfo{}
    |> TouristInfo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tourist_info.

  ## Examples

      iex> update_tourist_info(tourist_info, %{field: new_value})
      {:ok, %TouristInfo{}}

      iex> update_tourist_info(tourist_info, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tourist_info(%TouristInfo{} = tourist_info, attrs) do
    tourist_info
    |> TouristInfo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tourist_info.

  ## Examples

      iex> delete_tourist_info(tourist_info)
      {:ok, %TouristInfo{}}

      iex> delete_tourist_info(tourist_info)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tourist_info(%TouristInfo{} = tourist_info) do
    Repo.delete(tourist_info)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tourist_info changes.

  ## Examples

      iex> change_tourist_info(tourist_info)
      %Ecto.Changeset{data: %TouristInfo{}}

  """
  def change_tourist_info(%TouristInfo{} = tourist_info, attrs \\ %{}) do
    TouristInfo.changeset(tourist_info, attrs)
  end

  alias Yachanakuy.Tourism.Package

  @doc """
  Returns the list of packages.

  ## Examples

      iex> list_packages()
      [%Package{}, ...]

  """
  def list_packages do
    Repo.all(Package)
  end

  @doc """
  Gets a single package.

  Raises `Ecto.NoResultsError` if the Package does not exist.

  ## Examples

      iex> get_package!(123)
      %Package{}

      iex> get_package!(456)
      ** (Ecto.NoResultsError)

  """
  def get_package!(id) do
    Repo.get!(Package, id)
  end

  @doc """
  Gets a single package by ID.

  Returns nil if the Package does not exist.

  ## Examples

      iex> get_package(123)
      %Package{}

      iex> get_package(456)
      nil

  """
  def get_package(id) do
    Repo.get(Package, id)
  end

  @doc """
  Creates a package.

  ## Examples

      iex> create_package(%{field: value})
      {:ok, %Package{}}

      iex> create_package(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_package(attrs) do
    %Package{}
    |> Package.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a package.

  ## Examples

      iex> update_package(package, %{field: new_value})
      {:ok, %Package{}}

      iex> update_package(package, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_package(%Package{} = package, attrs) do
    package
    |> Package.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a package.

  ## Examples

      iex> delete_package(package)
      {:ok, %Package{}}

      iex> delete_package(package)
      {:error, %Ecto.Changeset{}}

  """
  def delete_package(%Package{} = package) do
    Repo.delete(package)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking package changes.

  ## Examples

      iex> change_package(package)
      %Ecto.Changeset{data: %Package{}}

  """
  def change_package(%Package{} = package, attrs \\ %{}) do
    Package.changeset(package, attrs)
  end
end
