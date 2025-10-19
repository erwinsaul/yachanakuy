defmodule Yachanakuy.Authorization.Policy do
  @moduledoc """
  Module for authorization policies and business rules.
  Defines what each role can do in the system.
  """

  # Admin can do everything
  def can_access?(_resource, "admin"), do: true

  # Supervisor (encargado_comision) can access commissions and related resources
  def can_access?(:commission, "encargado_comision"), do: true
  def can_access?(:commission_operator, "encargado_comision"), do: true
  def can_access?(:commission_summary, "encargado_comision"), do: true
  def can_access?(:my_activity, "encargado_comision"), do: true

  # Staff (operador) can access delivery and attendance related resources
  def can_access?(:credential_delivery, "operador"), do: true
  def can_access?(:material_delivery, "operador"), do: true
  def can_access?(:meal_delivery, "operador"), do: true
  def can_access?(:session_attendance, "operador"), do: true
  def can_access?(:my_activity, "operador"), do: true

  # Users can access public resources and their own information
  def can_access?(:attendee, "user"), do: true
  def can_access?(:home, _role), do: true
  def can_access?(:program, _role), do: true
  def can_access?(:speakers, _role), do: true
  def can_access?(:registration, _role), do: true

  # Default: denied
  def can_access?(_resource, _role), do: false
end