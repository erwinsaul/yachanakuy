defmodule YachanakuyWeb.Staff.CredentialDeliveryLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Registration

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_scope].user

    socket = assign(socket,
      current_user: current_user,
      attendee: nil,
      scanned_qr: nil,
      success_message: nil,
      error_message: nil,
      page: "staff_credential"
    )

    {:ok, socket}
  end

  def handle_event("scan_qr", %{"qr_code" => qr_code}, socket) do
    # Buscar al participante por el código QR
    attendee = Registration.get_attendee_by_qr_code(qr_code)  # Esta función necesitaría ser implementada
    
    if attendee do
      # Verificar si ya se entregó la credencial
      if attendee.credencial_entregada do
        socket = assign(socket, 
          error_message: "La credencial ya fue entregada previamente a este participante."
        )
        {:noreply, socket}
      else
        # Actualizar el estado de entrega de credencial
        updated_attendee = update_credential_delivery(attendee, socket.assigns.current_user)
        
        socket = assign(socket, 
          attendee: updated_attendee,
          scanned_qr: qr_code,
          success_message: "Credencial registrada como entregada exitosamente"
        )
        {:noreply, socket}
      end
    else
      socket = assign(socket, 
        error_message: "Código QR no encontrado o no válido."
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

  def handle_event("confirm_delivery", %{"id" => attendee_id}, socket) do
    attendee = Registration.get_attendee!(String.to_integer(attendee_id))
    current_user = socket.assigns.current_user
    
    case Yachanakuy.Deliveries.deliver_credential(attendee, current_user) do
      {:ok, updated_attendee} ->
        socket = assign(socket, 
          attendee: updated_attendee,
          success_message: "Credencial registrada como entregada exitosamente",
          error_message: nil
        )
        {:noreply, socket}
      {:error, message} ->
        socket = assign(socket, 
          error_message: message
        )
        {:noreply, socket}
    end
  end

  defp update_credential_delivery(attendee, user) do
    # Esta función simula la actualización del estado de entrega de credencial
    # En la implementación real, se llamaría al contexto con la función apropiada
    {:ok, updated_attendee} = Registration.update_attendee(attendee, %{
      credencial_entregada: true,
      fecha_entrega_credencial: DateTime.utc_now(),
      quien_entrego_credencial: user.id
    })
    updated_attendee
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 max-w-4xl">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Escanear Credenciales</h1>
      
      <!-- Scanner QR -->
      <div class="bg-white rounded-lg shadow-md p-6 mb-8">
        <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Escanear Código QR</h2>
        
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
        
        <%= if @attendee do %>
          <div class="border border-gray-200 rounded-lg p-6 mb-4">
            <h2 class="text-xl font-bold mb-4 text-center text-[#144D85]">Información del Participante</h2>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <p class="font-semibold">Nombre:</p>
                <p><%= @attendee.nombre_completo %></p>
              </div>
              
              <div>
                <p class="font-semibold">Número de Documento:</p>
                <p>#<%= @attendee.numero_documento %></p>
              </div>
              
              <div>
                <p class="font-semibold">Categoría:</p>
                <p><%= get_category_name(@attendee.category_id) %></p>
              </div>
              
              <div>
                <p class="font-semibold">Email:</p>
                <p><%= @attendee.email %></p>
              </div>
            </div>
            
            <div class="mt-4">
              <p class="font-semibold">Estado de Credencial:</p>
              <span class={
                "px-2 inline-flex text-xs leading-5 font-semibold rounded-full " <>
                if @attendee.credencial_entregada do
                  "bg-green-100 text-green-800"
                else
                  "bg-yellow-100 text-yellow-800"
                end
              }>
                <%= if @attendee.credencial_entregada, do: "Entregada", else: "Pendiente" %>
              </span>
            </div>
            
            <%= if !@attendee.credencial_entregada && @scanned_qr do %>
              <div class="mt-6 text-center">
                <button 
                  phx-click="confirm_delivery" 
                  phx-value-id={@attendee.id}
                  class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-6 rounded-md transition duration-300"
                >
                  Confirmar Entrega de Credencial
                </button>
              </div>
            <% end %>
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
