defmodule Yachanakuy.SettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Yachanakuy.Settings` context.
  """

  @doc """
  Generate a module_configuration.
  """
  def module_configuration_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        enabled: true,
        module_name: "some module_name"
      })

    {:ok, module_configuration} = Yachanakuy.Settings.create_module_configuration(scope, attrs)
    module_configuration
  end
end
