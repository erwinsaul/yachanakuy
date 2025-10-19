defmodule YachanakuyWeb.Staff.DashboardLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Deliveries

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_scope][:user]
    
    # Contadores para mostrar en el dashboard
    credential_deliveries = get_credential_deliveries_count(current_user)
    material_deliveries = get_material_deliveries_count(current_user)
    meal_deliveries = get_meal_deliveries_count(current_user)
    session_attendances = get_session_attendances_count(current_user)
    
    # Subscribe to user-specific updates
    if connected?(socket) do
      Yachanakuy.Dashboard.Broadcast.subscribe_user(current_user.id)
    end
    
    socket = assign(socket,
      current_user: current_user,
      credential_deliveries: credential_deliveries,
      material_deliveries: material_deliveries,
      meal_deliveries: meal_deliveries,
      session_attendances: session_attendances,
      page: "staff_dashboard"
    )
    
    {:ok, socket}
  end

  # Handle real-time updates
  def handle_info({:delivery_made, _payload}, socket) do
    # Update delivery counts based on the payload
    current_user = socket.assigns.current_user
    
    # Refresh counts
    credential_deliveries = get_credential_deliveries_count(current_user)
    material_deliveries = get_material_deliveries_count(current_user)
    meal_deliveries = get_meal_deliveries_count(current_user)
    session_attendances = get_session_attendances_count(current_user)
    
    socket = assign(socket,
      credential_deliveries: credential_deliveries,
      material_deliveries: material_deliveries,
      meal_deliveries: meal_deliveries,
      session_attendances: session_attendances
    )
    
    {:noreply, socket}
  end

  def handle_info(_other, socket) do
    {:noreply, socket}
  end

  defp get_credential_deliveries_count(user) do
    # Contar credenciales entregadas por este usuario
    Deliveries.count_credential_deliveries_by_user(user.id)
  end

  defp get_material_deliveries_count(user) do
    # Contar materiales entregados por este usuario
    Deliveries.count_material_deliveries_by_user(user.id)
  end

  defp get_meal_deliveries_count(user) do
    # Contar refrigerios entregados por este usuario
    Deliveries.count_meal_deliveries_by_user(user.id)
  end

  defp get_session_attendances_count(user) do
    # Contar asistencias registradas por este usuario
    Deliveries.count_session_attendances_by_user(user.id)
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Panel de Staff - <%= @current_user.nombre_completo %></h1>
      
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <!-- Credenciales Entregadas -->
        <div class="bg-white rounded-lg shadow-md p-6 border-l-4 border-[#144D85]">
          <h3 class="text-lg font-semibold text-gray-500">Credenciales Entregadas</h3>
          <p class="text-3xl font-bold text-[#144D85]"><%= @credential_deliveries %></p>
        </div>
        
        <!-- Materiales Entregados -->
        <div class="bg-white rounded-lg shadow-md p-6 border-l-4 border-green-500">
          <h3 class="text-lg font-semibold text-gray-500">Materiales Entregados</h3>
          <p class="text-3xl font-bold text-green-500"><%= @material_deliveries %></p>
        </div>
        
        <!-- Refrigerios Entregados -->
        <div class="bg-white rounded-lg shadow-md p-6 border-l-4 border-yellow-500">
          <h3 class="text-lg font-semibold text-gray-500">Refrigerios Entregados</h3>
          <p class="text-3xl font-bold text-yellow-500"><%= @meal_deliveries %></p>
        </div>
        
        <!-- Asistencias Registradas -->
        <div class="bg-white rounded-lg shadow-md p-6 border-l-4 border-purple-500">
          <h3 class="text-lg font-semibold text-gray-500">Asistencias Registradas</h3>
          <p class="text-3xl font-bold text-purple-500"><%= @session_attendances %></p>
        </div>
      </div>
      
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Acciones Rápidas -->
        <div class="bg-white rounded-lg shadow-md p-6">
          <h2 class="text-xl font-bold mb-4 text-[#144D85]">Acciones Rápidas</h2>
          <div class="space-y-3">
            <.link navigate={~p"/staff/acreditacion"} class="block bg-[#144D85] hover:bg-[#0d3a66] text-white py-2 px-4 rounded-md transition duration-300">
              Escanear Credenciales
            </.link>
            <.link navigate={~p"/staff/materiales"} class="block bg-[#144D85] hover:bg-[#0d3a66] text-white py-2 px-4 rounded-md transition duration-300">
              Escanear Materiales
            </.link>
            <.link navigate={~p"/staff/refrigerios"} class="block bg-[#144D85] hover:bg-[#0d3a66] text-white py-2 px-4 rounded-md transition duration-300">
              Registrar Refrigerios
            </.link>
            <.link navigate={~p"/staff/asistencia"} class="block bg-[#144D85] hover:bg-[#0d3a66] text-white py-2 px-4 rounded-md transition duration-300">
              Registrar Asistencia a Sesiones
            </.link>
          </div>
        </div>
        
        <!-- Mi Actividad -->
        <div class="bg-white rounded-lg shadow-md p-6">
          <h2 class="text-xl font-bold mb-4 text-[#144D85]">Mi Actividad Reciente</h2>
          <p class="text-gray-600">Aquí se mostrarán las últimas actividades registradas por ti...</p>
          <!-- En una implementación completa, aquí se mostraría una lista de actividades recientes -->
        </div>
      </div>
    </div>
    """
  end
end
