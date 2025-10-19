defmodule YachanakuyWeb.Admin.AttendeeReviewLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Registration
  alias Yachanakuy.Events

  def mount(%{"id" => id}, _session, socket) do
    attendee = Registration.get_attendee!(String.to_integer(id))
    categories = Events.list_attendee_categories()
    
    if attendee.estado != "pendiente_revision" do
      {:ok, push_navigate(socket, to: "/admin/attendees")}
    else
      {:ok, assign(socket, 
        attendee: attendee, 
        categories: categories,
        page: "review_attendee"
      )}
    end
  end

  def handle_event("approve", _params, socket) do
    current_user = socket.assigns.current_user || %{id: 1, nombre_completo: "Admin", rol: "admin"}
    attendee = socket.assigns.attendee
    
    case Registration.approve_attendee(attendee, current_user) do
      {:ok, updated_attendee} ->
        socket = assign(socket, 
          attendee: updated_attendee,
          message: "Participante aprobado exitosamente"
        )
        {:noreply, push_navigate(socket, to: "/admin/attendees")}
      {:error, changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("reject", %{"motivo" => motivo}, socket) do
    current_user = socket.assigns.current_user || %{id: 1, nombre_completo: "Admin", rol: "admin"}
    attendee = socket.assigns.attendee
    
    case Registration.reject_attendee(attendee, current_user, motivo) do
      {:ok, updated_attendee} ->
        socket = assign(socket, 
          attendee: updated_attendee,
          message: "Participante rechazado exitosamente"
        )
        {:noreply, push_navigate(socket, to: "/admin/attendees")}
      {:error, changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 max-w-4xl">
      <h1 class="text-3xl font-bold mb-6 text-[#144D85]">Revisión de Inscripción</h1>
      
      <div class="bg-white rounded-lg shadow-md p-6 mb-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
          <div>
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Información del Participante</h2>
            <div class="space-y-2">
              <p><span class="font-medium">Nombre:</span> <%= @attendee.nombre_completo %></p>
              <p><span class="font-medium">Documento:</span> <%= @attendee.numero_documento %></p>
              <p><span class="font-medium">Email:</span> <%= @attendee.email %></p>
              <p><span class="font-medium">Teléfono:</span> <%= @attendee.telefono || "No proporcionado" %></p>
              <p><span class="font-medium">Institución:</span> <%= @attendee.institucion || "No proporcionada" %></p>
              <p>
                <span class="font-medium">Categoría:</span> 
                <%= Enum.find(@categories, &(to_string(&1.id) == to_string(@attendee.category_id))).nombre %>
              </p>
            </div>
          </div>
          
          <div>
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Documentos</h2>
            <div class="space-y-4">
              <div>
                <p class="font-medium">Foto:</p>
                <%= if @attendee.foto do %>
                  <img src={@attendee.foto} alt="Foto del participante" class="max-w-xs max-h-32 mt-2 rounded border" />
                <% else %>
                  <p class="text-gray-500">No subida</p>
                <% end %>
              </div>
              
              <div>
                <p class="font-medium">Comprobante de pago:</p>
                <%= if @attendee.comprobante_pago do %>
                  <a href={@attendee.comprobante_pago} target="_blank" class="text-blue-600 hover:underline">Ver comprobante</a>
                <% else %>
                  <p class="text-gray-500">No subido</p>
                <% end %>
              </div>
            </div>
          </div>
        </div>
        
        <div class="flex space-x-4">
          <button 
            phx-click="approve"
            class="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded"
          >
            Aprobar Inscripción
          </button>
          
          <div phx-click-away={JS.push("close_modal")}>
            <button 
              id="reject-button"
              class="bg-red-600 hover:bg-red-700 text-white font-bold py-2 px-4 rounded"
              phx-hook="ToggleModal"
              phx-value-target="reject-modal"
            >
              Rechazar Inscripción
            </button>
            
            <div id="reject-modal" class="hidden fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
              <div class="bg-white rounded-lg p-6 max-w-md w-full">
                <h3 class="text-lg font-semibold mb-4">Rechazar Inscripción</h3>
                <form phx-submit="reject">
                  <div class="mb-4">
                    <label class="block text-gray-700 font-medium mb-2">Motivo de rechazo:</label>
                    <textarea name="motivo" 
                      class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                      rows="4"
                      required
                    ></textarea>
                  </div>
                  
                  <div class="flex justify-end space-x-3">
                    <button 
                      id="cancel-button"
                      type="button"
                      class="bg-gray-300 hover:bg-gray-400 text-gray-800 font-bold py-2 px-4 rounded"
                      phx-hook="ToggleModal"
                      phx-value-target="reject-modal"
                    >
                      Cancelar
                    </button>
                    <button 
                      type="submit"
                      class="bg-red-600 hover:bg-red-700 text-white font-bold py-2 px-4 rounded"
                    >
                      Rechazar
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
          
          <button 
            phx-click={JS.push("cancel")}
            class="bg-gray-600 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded"
          >
            Cancelar
          </button>
        </div>
      </div>
    </div>
    """
  end
end