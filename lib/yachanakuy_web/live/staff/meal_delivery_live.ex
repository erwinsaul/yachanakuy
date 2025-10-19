defmodule YachanakuyWeb.Staff.MealDeliveryLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Deliveries
  alias Yachanakuy.Registration

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_scope][:user]
    
    # Obtener la lista de refrigerios disponibles
    meals = Deliveries.list_meals()
    
    socket = assign(socket,
      current_user: current_user,
      meals: meals,
      attendee: nil,
      selected_meal: nil,
      scanned_qr: nil,
      success_message: nil,
      error_message: nil,
      page: "staff_meal"
    )
    
    {:ok, socket}
  end

  def handle_event("scan_qr", %{"qr_code" => qr_code}, socket) do
    # Buscar al participante por el código QR
    attendee = Registration.get_attendee_by_qr_code(qr_code)  # Esta función necesitaría ser implementada
    
    if attendee do
      socket = assign(socket, 
        attendee: attendee,
        scanned_qr: qr_code
      )
      {:noreply, socket}
    else
      socket = assign(socket, 
        error_message: "Código QR no encontrado o no válido."
      )
      {:noreply, socket}
    end
  end

  def handle_event("select_meal", %{"meal_id" => meal_id}, socket) do
    meal = Deliveries.get_meal!(String.to_integer(meal_id))
    
    socket = assign(socket, 
      selected_meal: meal
    )
    {:noreply, socket}
  end

  def handle_event("confirm_delivery", _params, socket) do
    attendee = socket.assigns.attendee
    meal = socket.assigns.selected_meal
    current_user = socket.assigns.current_user
    
    # Verificar que no se haya entregado este refrigerio previamente a este participante
    existing_delivery = Deliveries.get_delivery_by_attendee_and_meal(attendee.id, meal.id)
    
    if existing_delivery do
      socket = assign(socket,
        error_message: "Este refrigerio ya fue entregado previamente a este participante."
      )
      {:noreply, socket}
    else
      # Registrar la entrega
      {:ok, _delivery} = Deliveries.create_meal_delivery(%{
        attendee_id: attendee.id,
        meal_id: meal.id,
        entregado_por: current_user.id,
        fecha_entrega: DateTime.utc_now()
      })
      
      socket = assign(socket,
        success_message: "Refrigerio entregado exitosamente a #{attendee.nombre_completo}",
        attendee: nil,
        selected_meal: nil,
        scanned_qr: nil
      )
      {:noreply, socket}
    end
  end

  def handle_event("manual_search", %{"documento" => documento}, socket) do
    # Buscar por número de documento
    attendee = Registration.get_attendee_by_documento(documento)  # Esta función necesitaría ser implementada
    
    if attendee do
      socket = assign(socket, 
        attendee: attendee
      )
      {:noreply, socket}
    else
      socket = assign(socket, 
        error_message: "Participante no encontrado con ese número de documento."
      )
      {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 max-w-4xl">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Registrar Refrigerios</h1>
      
      <!-- Selección de refrigerio -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Seleccionar Refrigerio</h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for meal <- @meals do %>
            <div 
              class={
                "border rounded-lg p-4 cursor-pointer transition duration-300 " <>
                if @selected_meal && @selected_meal.id == meal.id do
                  "border-[#144D85] bg-blue-50"
                else
                  "border-gray-200 hover:border-[#144D85]"
                end
              }
              phx-click="select_meal" 
              phx-value-meal_id={meal.id}
            >
              <h3 class="font-semibold text-[#144D85]"><%= meal.nombre %></h3>
              <p class="text-sm text-gray-600"><%= meal.tipo %></p>
              <%= if meal.fecha do %>
                <p class="text-sm text-gray-600">
                  <%= Date.to_string(meal.fecha) %> 
                  <%= if meal.hora_desde && meal.hora_hasta do %>
                    (<%= Time.to_string(meal.hora_desde) %> - <%= Time.to_string(meal.hora_hasta) %>)
                  <% end %>
                </p>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
      
      <!-- Scanner QR -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Escanear Código QR del Participante</h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <div class="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center bg-gray-50">
              <div class="flex justify-center mb-4">
                <div class="w-48 h-48 bg-gray-200 border-2 border-dashed rounded-xl flex items-center justify-center text-gray-500">
                  Área de escaneo QR
                </div>
              </div>
              <p class="text-gray-600">Coloque el código QR dentro del área de escaneo</p>
            </div>
          </div>
          
          <div>
            <div class="mb-4">
              <.form
                :let={f}
                for={%{}}
                phx-submit="scan_qr"
                class="space-y-4"
              >
                <.input
                  field={f[:qr_code]}
                  type="text"
                  label="Código QR"
                  placeholder="Ingrese el código QR manualmente"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
                <button 
                  type="submit" 
                  class="w-full bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded-md transition duration-300"
                >
                  Escanear QR
                </button>
              </.form>
            </div>
            
            <div class="mt-6">
              <h3 class="text-lg font-medium mb-2 text-[#144D85]">Buscar manualmente</h3>
              <.form
                :let={f}
                for={%{}}
                phx-submit="manual_search"
                class="space-y-4"
              >
                <.input
                  field={f[:documento]}
                  type="text"
                  label="Número de documento"
                  placeholder="Número de documento"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
                <button 
                  type="submit" 
                  class="w-full bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-md transition duration-300"
                >
                  Buscar Participante
                </button>
              </.form>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Resultado -->
      <div class="bg-white rounded-lg shadow-md p-6">
        <%= if @success_message do %>
          <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
            <%= @success_message %>
          </div>
        <% end %>
        
        <%= if @error_message do %>
          <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
            <%= @error_message %>
          </div>
        <% end %>
        
        <%= if @attendee && @selected_meal do %>
          <div class="border border-gray-200 rounded-lg p-6 mb-4">
            <h2 class="text-xl font-bold mb-4 text-center text-[#144D85]">Confirmar Entrega</h2>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div>
                <h3 class="text-lg font-semibold mb-2 text-[#144D85]">Participante</h3>
                <div class="bg-gray-50 p-4 rounded">
                  <p class="font-semibold"><%= @attendee.nombre_completo %></p>
                  <p class="text-sm text-gray-600">Documento: #<%= @attendee.numero_documento %></p>
                  <p class="text-sm text-gray-600">Categoría: <%= get_category_name(@attendee.category_id) %></p>
                </div>
              </div>
              
              <div>
                <h3 class="text-lg font-semibold mb-2 text-[#144D85]">Refrigerio</h3>
                <div class="bg-gray-50 p-4 rounded">
                  <p class="font-semibold"><%= @selected_meal.nombre %></p>
                  <p class="text-sm text-gray-600">Tipo: <%= @selected_meal.tipo %></p>
                  <%= if @selected_meal.fecha do %>
                    <p class="text-sm text-gray-600">Fecha: <%= Date.to_string(@selected_meal.fecha) %></p>
                  <% end %>
                </div>
              </div>
            </div>
            
            <div class="text-center">
              <button 
                phx-click="confirm_delivery"
                class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-3 px-6 rounded-md transition duration-300"
              >
                Confirmar Entrega de Refrigerio
              </button>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp get_category_name(category_id) do
    # Esta es una implementación simple, en la práctica se debería obtener de la base de datos
    case category_id do
      1 -> "Estudiante"
      2 -> "Profesional" 
      3 -> "Ponente"
      _ -> "Otro"
    end
  end
end
