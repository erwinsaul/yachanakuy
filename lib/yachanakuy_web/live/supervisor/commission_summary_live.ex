defmodule YachanakuyWeb.Supervisor.CommissionSummaryLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Commissions
  alias Yachanakuy.Deliveries

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]

    if authorized?(current_user) do
      commissions = get_user_commissions(current_user)
      
      commission_stats = Enum.map(commissions, fn commission ->
        stats = %{
          deliveries: Deliveries.count_deliveries_by_commission(commission.id),
          completed_attendances: Deliveries.count_attendances_by_commission(commission.id),
          operators_count: Commissions.count_operators_in_commission(commission.id)
        }
        
        Map.put(commission, :stats, stats)
      end)

      {:ok,
       socket
       |> assign(:page_title, "Resumen de Comisión - Encargado")
       |> assign(:commission_stats, commission_stats)}
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