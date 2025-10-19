defmodule YachanakuyWeb.Admin.DashboardLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Registration
  alias Yachanakuy.Program

  def mount(_params, _session, socket) do
    # Contadores para mostrar en el dashboard
    total_attendees = Registration.count_attendees()
    pending_attendees = Registration.count_pending_reviews()
    total_speakers = Program.count_speakers()
    total_sessions = Program.count_sessions()
    
    # Subscribe to admin dashboard updates
    if connected?(socket) do
      Yachanakuy.Dashboard.Broadcast.subscribe_role("admin")
    end
    
    socket = assign(socket,
      total_attendees: total_attendees,
      pending_attendees: pending_attendees,
      total_speakers: total_speakers,
      total_sessions: total_sessions,
      page: "admin_dashboard"
    )
    
    {:ok, socket}
  end

  def handle_info({:attendee_registered, _payload}, socket) do
    # Update attendee counts
    updated_total = socket.assigns.total_attendees + 1
    updated_pending = socket.assigns.pending_attendees + 1
    
    socket = assign(socket,
      total_attendees: updated_total,
      pending_attendees: updated_pending
    )
    
    {:noreply, socket}
  end

  def handle_info({:attendee_approved, _payload}, socket) do
    # Update attendee counts
    updated_pending = max(0, socket.assigns.pending_attendees - 1)
    
    socket = assign(socket,
      pending_attendees: updated_pending
    )
    
    {:noreply, socket}
  end

  def handle_info({:delivery_made, _payload}, socket) do
    # Update delivery counts if needed
    # In this case, we might want to show delivery stats somewhere
    {:noreply, socket}
  end

  def handle_info(_other, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85] dark:text-blue-400">Panel de Administración</h1>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <!-- Total Attendees Card -->
        <div class="bg-white dark:bg-gray-700 rounded-lg shadow-md p-6 border-l-4 border-[#144D85] dark:border-blue-400">
          <h3 class="text-lg font-semibold text-gray-500 dark:text-gray-300">Total Participantes</h3>
          <p class="text-3xl font-bold text-[#144D85] dark:text-blue-400"><%= @total_attendees %></p>
        </div>

        <!-- Pending Reviews Card -->
        <div class="bg-white dark:bg-gray-700 rounded-lg shadow-md p-6 border-l-4 border-yellow-500 dark:border-yellow-400">
          <h3 class="text-lg font-semibold text-gray-500 dark:text-gray-300">Pendientes de Revisión</h3>
          <p class="text-3xl font-bold text-yellow-500 dark:text-yellow-400"><%= @pending_attendees %></p>
        </div>

        <!-- Total Speakers Card -->
        <div class="bg-white dark:bg-gray-700 rounded-lg shadow-md p-6 border-l-4 border-[#B33536] dark:border-red-400">
          <h3 class="text-lg font-semibold text-gray-500 dark:text-gray-300">Total Expositores</h3>
          <p class="text-3xl font-bold text-[#B33536] dark:text-red-400"><%= @total_speakers %></p>
        </div>

        <!-- Total Sessions Card -->
        <div class="bg-white dark:bg-gray-700 rounded-lg shadow-md p-6 border-l-4 border-green-500 dark:border-green-400">
          <h3 class="text-lg font-semibold text-gray-500 dark:text-gray-300">Total Sesiones</h3>
          <p class="text-3xl font-bold text-green-500 dark:text-green-400"><%= @total_sessions %></p>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Quick Actions -->
        <div class="bg-white dark:bg-gray-700 rounded-lg shadow-md p-6">
          <h2 class="text-xl font-bold mb-4 text-[#144D85] dark:text-blue-400">Acciones Rápidas</h2>
          <div class="space-y-3">
            <.link navigate={~p"/admin/attendees"} class="block bg-[#144D85] hover:bg-[#0d3a66] dark:bg-blue-600 dark:hover:bg-blue-700 text-white py-2 px-4 rounded-md transition duration-300">
              Gestionar Participantes
            </.link>
            <.link navigate={~p"/admin/speakers"} class="block bg-[#144D85] hover:bg-[#0d3a66] dark:bg-blue-600 dark:hover:bg-blue-700 text-white py-2 px-4 rounded-md transition duration-300">
              Gestionar Expositores
            </.link>
            <.link navigate={~p"/admin/sessions"} class="block bg-[#144D85] hover:bg-[#0d3a66] dark:bg-blue-600 dark:hover:bg-blue-700 text-white py-2 px-4 rounded-md transition duration-300">
              Gestionar Sesiones
            </.link>
            <.link navigate={~p"/admin/settings"} class="block bg-[#144D85] hover:bg-[#0d3a66] dark:bg-blue-600 dark:hover:bg-blue-700 text-white py-2 px-4 rounded-md transition duration-300">
              Configuración del Congreso
            </.link>
          </div>
        </div>

        <!-- Recent Activity -->
        <div class="bg-white dark:bg-gray-700 rounded-lg shadow-md p-6">
          <h2 class="text-xl font-bold mb-4 text-[#144D85] dark:text-blue-400">Actividad Reciente</h2>
          <p class="text-gray-600 dark:text-gray-300">Últimas inscripciones y revisiones...</p>
          <!-- En una implementación completa, aquí se mostraría una lista de actividades recientes -->
        </div>
      </div>
    </div>
    """
  end
end
