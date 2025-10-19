defmodule YachanakuyWeb.Staff.MyActivityLive do
  use YachanakuyWeb, :live_view

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_scope][:user]
    
    # Obtener las actividades del usuario actual
    credential_deliveries = get_credential_deliveries(current_user)
    material_deliveries = get_material_deliveries(current_user)
    meal_deliveries = get_meal_deliveries(current_user)
    session_attendances = get_session_attendances(current_user)
    
    socket = assign(socket,
      current_user: current_user,
      credential_deliveries: credential_deliveries,
      material_deliveries: material_deliveries,
      meal_deliveries: meal_deliveries,
      session_attendances: session_attendances,
      page: "staff_my_activity"
    )
    
    {:ok, socket}
  end

  defp get_credential_deliveries(_user) do
    # Simular la obtención de credenciales entregadas por el usuario
    # En la implementación real, esto se haría con una consulta al contexto
    []
  end

  defp get_material_deliveries(_user) do
    # Simular la obtención de materiales entregados por el usuario
    # En la implementación real, esto se haría con una consulta al contexto
    []
  end

  defp get_meal_deliveries(_user) do
    # Simular la obtención de refrigerios entregados por el usuario
    # En la implementación real, esto se haría con una consulta al contexto
    []
  end

  defp get_session_attendances(_user) do
    # Simular la obtención de asistencias registradas por el usuario
    # En la implementación real, esto se haría con una consulta al contexto
    []
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Mi Actividad - <%= @current_user.nombre_completo %></h1>
      
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <!-- Resumen de actividades -->
        <div class="bg-white rounded-lg shadow-md p-6">
          <h2 class="text-xl font-bold mb-4 text-[#144D85]">Resumen de Actividades</h2>
          
          <div class="space-y-4">
            <div class="flex justify-between items-center pb-2 border-b">
              <span class="font-medium">Credenciales entregadas:</span>
              <span class="font-bold text-[#144D85]"><%= length(@credential_deliveries) %></span>
            </div>
            
            <div class="flex justify-between items-center pb-2 border-b">
              <span class="font-medium">Materiales entregados:</span>
              <span class="font-bold text-green-600"><%= length(@material_deliveries) %></span>
            </div>
            
            <div class="flex justify-between items-center pb-2 border-b">
              <span class="font-medium">Refrigerios registrados:</span>
              <span class="font-bold text-yellow-600"><%= length(@meal_deliveries) %></span>
            </div>
            
            <div class="flex justify-between items-center pb-2 border-b">
              <span class="font-medium">Asistencias registradas:</span>
              <span class="font-bold text-purple-600"><%= length(@session_attendances) %></span>
            </div>
          </div>
        </div>
        
        <!-- Actividad detallada -->
        <div class="bg-white rounded-lg shadow-md p-6">
          <h2 class="text-xl font-bold mb-4 text-[#144D85]">Actividad Reciente</h2>
          
          <div class="text-gray-500 text-center py-8">
            <p>Listado de actividades recientes...</p>
            <p class="mt-2 text-sm">Aquí se mostrarían las últimas actividades registradas por ti</p>
          </div>
        </div>
      </div>
      
      <!-- Historial específico por tipo -->
      <div class="mt-8 bg-white rounded-lg shadow-md p-6">
        <h2 class="text-xl font-bold mb-4 text-[#144D85]">Historial de Entregas</h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Credenciales -->
          <div>
            <h3 class="font-semibold mb-2 text-[#144D85]">Credenciales</h3>
            <%= if @credential_deliveries == [] do %>
              <p class="text-gray-500 text-sm">No hay entregas registradas</p>
            <% else %>
              <div class="space-y-2">
                <!-- En una implementación real, se mostrarían los datos reales -->
                <div class="text-sm">Ejemplo: Credencial entregada a Juan Pérez - 2023-10-15 10:30</div>
              </div>
            <% end %>
          </div>
          
          <!-- Materiales -->
          <div>
            <h3 class="font-semibold mb-2 text-[#144D85]">Materiales</h3>
            <%= if @material_deliveries == [] do %>
              <p class="text-gray-500 text-sm">No hay entregas registradas</p>
            <% else %>
              <div class="space-y-2">
                <!-- En una implementación real, se mostrarían los datos reales -->
                <div class="text-sm">Ejemplo: Materiales entregados a Ana Gómez - 2023-10-15 11:15</div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end