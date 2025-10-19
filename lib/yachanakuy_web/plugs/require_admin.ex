defmodule YachanakuyWeb.RequireAdmin do
  @moduledoc """
  Plug to require admin role for accessing routes.
  Redirects non-admin users to login page with error message.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(options), do: options

  def call(conn, _options) do
    case get_session_user_role(conn) do
      "admin" ->
        conn
      _ ->
        conn
        |> put_flash(:error, "Acceso denegado. Se requiere rol de administrador.")
        |> redirect(to: "/users/log-in")
        |> halt()
    end
  end

  defp get_session_user_role(conn) do
    case conn.assigns[:current_user] do
      nil -> nil
      user -> user.rol
    end
  end
end