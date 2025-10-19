defmodule YachanakuyWeb.Supervisor.OperatorsLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Accounts
  alias Yachanakuy.Commissions

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]

    if authorized?(current_user) do
      commissions = get_user_commissions(current_user)
      
      operators = Accounts.list_operators_by_commissions(commissions)

      {:ok,
       socket
       |> assign(:page_title, "Operadores - Encargado")
       |> assign(:commissions, commissions)
       |> assign(:operators, operators)}
    else
      {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  defp authorized?(%{rol: "encargado_comision"}), do: true
  defp authorized?(_), do: false

  defp get_user_commissions(user) do
    Commissions.list_commissions_by_supervisor(user.id)
  end
end