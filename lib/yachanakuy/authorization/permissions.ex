defmodule Yachanakuy.Authorization.Permissions do
  @moduledoc """
  Module for handling specific permissions and authorization checks.
  Provides functions to verify if a user has permission to perform specific actions.
  """

  alias Yachanakuy.Authorization.Policy

  @doc """
  Check if the user can access a specific resource
  """
  def user_can_access?(user, resource) when is_map(user) do
    Policy.can_access?(resource, user.rol)
  end
  def user_can_access?(_user, _resource), do: false

  @doc """
  Check if the user can perform a specific action on a resource
  """
  def can_perform_action?(user, action, resource) when is_map(user) do
    case Policy.can_access?(resource, user.rol) do
      true -> check_action_permission(user, action, resource)
      false -> false
    end
  end
  def can_perform_action?(_user, _action, _resource), do: false

  # Specific action checks
  defp check_action_permission(_user, :read, _resource), do: true
  defp check_action_permission(_user, :create, :attendee), do: true
  defp check_action_permission(%{rol: "admin"}, _action, _resource), do: true
  defp check_action_permission(%{rol: "encargado_comision"}, action, :commission) when action in [:read, :update], do: true
  defp check_action_permission(%{rol: "operador"}, action, resource) when resource in [:credential_delivery, :material_delivery, :meal_delivery, :session_attendance] and action in [:read, :create], do: true
  defp check_action_permission(_user, _action, _resource), do: false

  @doc """
  Check if user has a specific role
  """
  def has_role?(user, expected_role) when is_map(user) do
    user.rol == expected_role
  end
  def has_role?(_user, _expected_role), do: false

  @doc """
  Check if user has any of the specified roles
  """
  def has_any_role?(user, roles) when is_map(user) and is_list(roles) do
    Enum.member?(roles, user.rol)
  end
  def has_any_role?(_user, _roles), do: false

  @doc """
  Check if user is an admin
  """
  def is_admin?(user), do: has_role?(user, "admin")

  @doc """
  Check if user is a supervisor (encargado_comision)
  """
  def is_supervisor?(user), do: has_role?(user, "encargado_comision")

  @doc """
  Check if user is staff (operador)
  """
  def is_staff?(user), do: has_role?(user, "operador")
end