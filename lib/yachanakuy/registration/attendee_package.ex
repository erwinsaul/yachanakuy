defmodule Yachanakuy.Registration.AttendeePackage do
  use Ecto.Schema
  import Ecto.Changeset

  alias Yachanakuy.Registration.Attendee
  alias Yachanakuy.Tourism.Package

  schema "attendee_packages" do
    belongs_to :attendee, Attendee
    belongs_to :package, Package

    timestamps()
  end

  @doc false
  def changeset(attendee_package, attrs) do
    attendee_package
    |> cast(attrs, [:attendee_id, :package_id])
    |> validate_required([:attendee_id, :package_id])
    |> foreign_key_constraint(:attendee_id)
    |> foreign_key_constraint(:package_id)
    |> unique_constraint(:attendee_id, name: :attendee_packages_attendee_id_index)
  end
end
