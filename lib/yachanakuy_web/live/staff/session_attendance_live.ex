defmodule YachanakuyWeb.Staff.SessionAttendanceLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Registration
  alias Yachanakuy.Program
  alias Yachanakuy.Deliveries

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_scope][:user]
    
    # Obtener la lista de sesiones disponibles
    sessions = Program.list_sessions()
    
    socket = assign(socket,
      current_user: current_user,
      sessions: sessions,
      attendee: nil,
      selected_session: nil,
      scanned_qr: nil,
      success_message: nil,
      error_message: nil,
      page: "staff_attendance"
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

  def handle_event("select_session", %{"session_id" => session_id}, socket) do
    session = Program.get_session!(String.to_integer(session_id))
    
    socket = assign(socket, 
      selected_session: session
    )
    {:noreply, socket}
  end

  def handle_event("confirm_attendance", _params, socket) do
    attendee = socket.assigns.attendee
    session = socket.assigns.selected_session
    current_user = socket.assigns.current_user
    
    # Verificar que no se haya registrado asistencia previamente a esta sesión por este participante
    existing_attendance = Deliveries.get_attendance_by_attendee_and_session(attendee.id, session.id)
    
    if existing_attendance do
      socket = assign(socket,
        error_message: "La asistencia a esta sesión ya fue registrada previamente para este participante."
      )
      {:noreply, socket}
    else
      # Registrar la asistencia
      {:ok, _attendance} = Deliveries.create_session_attendance(%{
        attendee_id: attendee.id,
        session_id: session.id,
        escaneado_por: current_user.id,
        fecha_escaneo: DateTime.utc_now()
      })
      
      # Actualizar el contador de sesiones asistidas en el participante
      updated_sesiones_asistidas = (attendee.sesiones_asistidas || 0) + 1
      {:ok, _updated_attendee} = Registration.update_attendee(attendee, %{
        sesiones_asistidas: updated_sesiones_asistidas
      })
      
      socket = assign(socket,
        success_message: "Asistencia registrada exitosamente para #{attendee.nombre_completo} en la sesión #{session.titulo}",
        attendee: nil,
        selected_session: nil,
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
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Registrar Asistencia a Sesiones</h1>
      
      <!-- Selección de sesión -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Seleccionar Sesión</h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <%= for session <- @sessions do %>
            <div 
              class={
                "border rounded-lg p-4 cursor-pointer transition duration-300 " <>
                if @selected_session && @selected_session.id == session.id do
                  "border-[#144D85] bg-blue-50"
                else
                  "border-gray-200 hover:border-[#144D85]"
                end
              }
              phx-click="select_session" 
              phx-value-session_id={session.id}
            >
              <h3 class="font-semibold text-[#144D85]"><%= session.titulo %></h3>
              <p class="text-sm text-gray-600"><%= session.tipo %></p>
              <%= if session.fecha do %>
                <p class="text-sm text-gray-600">
                  <%= Date.to_string(session.fecha) %> 
                  <%= Time.to_string(session.hora_inicio) %> - <%= Time.to_string(session.hora_fin) %>
                </p>
              <% end %>
              <%= if session.room do %>
                <p class="text-sm text-gray-600">Sala: <%= session.room.nombre %></p>
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
        
        <%= if @attendee && @selected_session do %>
          <div class="border border-gray-200 rounded-lg p-6 mb-4">
            <h2 class="text-xl font-bold mb-4 text-center text-[#144D85]">Confirmar Asistencia</h2>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div>
                <h3 class="text-lg font-semibold mb-2 text-[#144D85]">Participante</h3>
                <div class="bg-gray-50 p-4 rounded">
                  <p class="font-semibold"><%= @attendee.nombre_completo %></p>
                  <p class="text-sm text-gray-600">Documento: #<%= @attendee.numero_documento %></p>
                  <p class="text-sm text-gray-600">Categoría: <%= get_category_name(@attendee.category_id) %></p>
                  <p class="text-sm text-gray-600">Sesiones asistidas: <%= @attendee.sesiones_asistidas || 0 %></p>
                </div>
              </div>
              
              <div>
                <h3 class="text-lg font-semibold mb-2 text-[#144D85]">Sesión</h3>
                <div class="bg-gray-50 p-4 rounded">
                  <p class="font-semibold"><%= @selected_session.titulo %></p>
                  <p class="text-sm text-gray-600">Tipo: <%= @selected_session.tipo %></p>
                  <%= if @selected_session.fecha do %>
                    <p class="text-sm text-gray-600">Fecha: <%= Date.to_string(@selected_session.fecha) %></p>
                    <p class="text-sm text-gray-600">Hora: <%= Time.to_string(@selected_session.hora_inicio) %> - <%= Time.to_string(@selected_session.hora_fin) %></p>
                  <% end %>
                  <%= if @selected_session.room do %>
                    <p class="text-sm text-gray-600">Sala: <%= @selected_session.room.nombre %></p>
                  <% end %>
                </div>
              </div>
            </div>
            
            <div class="text-center">
              <button 
                phx-click="confirm_attendance"
                class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-3 px-6 rounded-md transition duration-300"
              >
                Confirmar Asistencia
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
