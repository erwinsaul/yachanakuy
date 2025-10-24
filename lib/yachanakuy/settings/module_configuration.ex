defmodule Yachanakuy.Settings.ModuleConfiguration do
  use Ecto.Schema
  import Ecto.Changeset

  schema "module_configurations" do
    field :module_name, :string
    field :enabled, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(module_configuration, attrs) do
    module_configuration
    |> cast(attrs, [:module_name, :enabled])
    |> validate_required([:module_name])
    |> validate_inclusion(:module_name, ["attendees", "speakers", "sessions", "rooms", "commissions", "event_info", "tourist_info", "packages"])
    |> validate_format(:module_name, ~r/^[a-z_]+$/, message: "must contain only lowercase letters and underscores")
  end
end
