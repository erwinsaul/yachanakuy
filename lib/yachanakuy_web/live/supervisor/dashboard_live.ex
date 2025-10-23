defmodule YachanakuyWeb.Supervisor.DashboardLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Commissions
  alias Yachanakuy.Deliveries
  alias Yachanakuy.Registration

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]

    if authorized?(current_user) do
      commissions = get_user_commissions(current_user)
      
      stats = %{
        total_attendees: Registration.count_attendees(),
        my_commissions: length(commissions),
        pending_reviews: Registration.count_pending_reviews(),
        total_deliveries: Deliveries.count_deliveries_by_user(current_user.id)
      }

      # Subscribe to supervisor dashboard updates
      if connected?(socket) do
        Yachanakuy.Dashboard.Broadcast.subscribe_role("encargado_comision")
      end

      {:ok,
       socket
       |> assign(:page_title, "Dashboard - Encargado")
       |> assign(:commissions, commissions)
       |> assign(:stats, stats)}
    else
      {:ok, push_navigate(socket, to: ~p"/")}
    end
  end

  @impl true
  # Handle real-time updates
  def handle_info({:attendee_registered, _payload}, socket) do
    # Update stats when a new attendee registers
    updated_stats = %{
      socket.assigns.stats |
      total_attendees: socket.assigns.stats.total_attendees + 1,
      pending_reviews: socket.assigns.stats.pending_reviews + 1
    }
    
    socket = assign(socket, stats: updated_stats)
    {:noreply, socket}
  end

  def handle_info({:attendee_approved, _payload}, socket) do
    # Update stats when an attendee is approved
    updated_stats = %{
      socket.assigns.stats |
      pending_reviews: max(0, socket.assigns.stats.pending_reviews - 1)
    }
    
    socket = assign(socket, stats: updated_stats)
    {:noreply, socket}
  end

  def handle_info({:delivery_made, _payload}, socket) do
    # Update stats when a delivery is made
    current_user = socket.assigns.current_user
    updated_stats = %{
      socket.assigns.stats |
      total_deliveries: Deliveries.count_deliveries_by_user(current_user.id)
    }
    
    socket = assign(socket, stats: updated_stats)
    {:noreply, socket}
  end

  def handle_info(_other, socket) do
    {:noreply, socket}
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Panel del Encargado</h1>
      
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <!-- Total Participants -->
        <div class="bg-white rounded-lg shadow-md p-6 border-l-4 border-[#144D85]">
          <h3 class="text-lg font-semibold text-gray-500">Total Participantes</h3>
          <p class="text-3xl font-bold text-[#144D85]"><%= @stats.total_attendees %></p>
        </div>
        
        <!-- My Commissions -->
        <div class="bg-white rounded-lg shadow-md p-6 border-l-4 border-[#B33536]">
          <h3 class="text-lg font-semibold text-gray-500">Mis Comisiones</h3>
          <p class="text-3xl font-bold text-[#B33536]"><%= @stats.my_commissions %></p>
        </div>
        
        <!-- Pending Reviews -->
        <div class="bg-white rounded-lg shadow-md p-6 border-l-4 border-yellow-500">
          <h3 class="text-lg font-semibold text-gray-500">Revisión Pendientes</h3>
          <p class="text-3xl font-bold text-yellow-500"><%= @stats.pending_reviews %></p>
        </div>
        
        <!-- Total Deliveries -->
        <div class="bg-white rounded-lg shadow-md p-6 border-l-4 border-green-500">
          <h3 class="text-lg font-semibold text-gray-500">Entregas Totales</h3>
          <p class="text-3xl font-bold text-green-500"><%= @stats.total_deliveries %></p>
        </div>
      </div>
      
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- My Commissions List -->
        <div class="bg-white rounded-lg shadow-md p-6">
          <h2 class="text-xl font-bold mb-4 text-[#144D85]">Mis Comisiones</h2>
          <%= if @commissions == [] do %>
            <p class="text-gray-600">No tienes comisiones asignadas.</p>
          <% else %>
            <div class="space-y-3">
              <%= for commission <- @commissions do %>
                <div class="flex items-center justify-between p-3 border border-gray-200 rounded-md">
                  <div>
                    <h3 class="font-medium text-gray-800"><%= commission.nombre %></h3>
                    <p class="text-sm text-gray-600">Código: <%= commission.codigo %></p>
                  </div>
                  <%!-- TODO: Implement commission details page
                  <div class="flex space-x-2">
                    <.link
                      navigate={~p"/supervisor/commissions/#{commission}"}
                      class="bg-[#144D85] hover:bg-[#0d3a66] text-white py-1 px-3 rounded-md text-sm transition duration-300"
                    >
                      Ver Detalles
                    </.link>
                  </div>
                  --%>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
        
        <!-- Recent Activity -->
        <div class="bg-white rounded-lg shadow-md p-6">
          <h2 class="text-xl font-bold mb-4 text-[#144D85]">Actividad Reciente</h2>
          <p class="text-gray-600">Aquí se mostrarán las últimas actividades de miembros de tus comisiones...</p>
          <!-- Real-time activity updates will be shown here -->
        </div>
      </div>
    </div>
    """
  end
end