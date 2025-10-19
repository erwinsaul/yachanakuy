defmodule YachanakuyWeb.Admin.RoomLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Program

  def mount(_params, _session, socket) do
    rooms = Program.list_rooms()
    
    changeset = Program.change_room(%Yachanakuy.Program.Room{})
    
    socket = assign(socket,
      rooms: rooms,
      changeset: changeset,
      editing_room: nil,
      page: "admin_rooms",
      success_message: nil
    )

    {:ok, socket}
  end

  def handle_event("save", %{"room" => room_params}, socket) do
    result = if socket.assigns.editing_room do
      Program.update_room(socket.assigns.editing_room, room_params)
    else
      Program.create_room(room_params)
    end
  
    case result do
      {:ok, _room} ->
        rooms = Program.list_rooms()
        changeset = Program.change_room(%Yachanakuy.Program.Room{})
  
        socket = assign(socket,
          rooms: rooms,
          changeset: changeset,
          editing_room: nil,
          success_message: if(socket.assigns.editing_room, do: "Sala actualizada", else: "Sala creada") <> " exitosamente"
        )
        {:noreply, socket}
  
      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("edit", %{"id" => id}, socket) do
    room = Program.get_room!(String.to_integer(id))
    changeset = Program.change_room(room)
    
    socket = assign(socket, 
      changeset: changeset,
      editing_room: room
    )
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    room = Program.get_room!(String.to_integer(id))
    {:ok, _} = Program.delete_room(room)
    
    rooms = Program.list_rooms()
    changeset = Program.change_room(%Yachanakuy.Program.Room{})
    
    socket = assign(socket, 
      rooms: rooms, 
      changeset: changeset,
      editing_room: nil,
      success_message: "Sala eliminada exitosamente"
    )
    {:noreply, socket}
  end

  def handle_event("cancel", _params, socket) do
    changeset = Program.change_room(%Yachanakuy.Program.Room{})
    
    socket = assign(socket, 
      changeset: changeset,
      editing_room: nil
    )
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Gestión de Salas</h1>
      
      <%= if @success_message do %>
        <div class="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6">
          <%= @success_message %>
        </div>
      <% end %>
      
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Formulario -->
        <div class="lg:col-span-1">
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">
              <%= if @editing_room, do: "Editar Sala", else: "Nueva Sala" %>
            </h2>
            
            <.form
              :let={f}
              for={@changeset}
              phx-submit="save"
              class="space-y-4"
            >
              <div>
                <.input field={f[:nombre]} type="text" label="Nombre de la Sala"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div>
                <.input field={f[:capacidad]} type="number" label="Capacidad"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div>
                <.input field={f[:ubicacion]} type="text" label="Ubicación/Dirección"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div class="pt-4">
                <button 
                  type="submit" 
                  class="w-full bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded-md transition duration-300"
                >
                  <%= if @editing_room, do: "Actualizar", else: "Crear" %>
                </button>
                
                <%= if @editing_room do %>
                  <button 
                    phx-click="cancel"
                    type="button"
                    class="w-full mt-2 bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-md transition duration-300"
                  >
                    Cancelar
                  </button>
                <% end %>
              </div>
            </.form>
          </div>
        </div>
        
        <!-- Lista de Salas -->
        <div class="lg:col-span-2">
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Lista de Salas</h2>
            
            <%= if @rooms == [] do %>
              <p class="text-gray-500 text-center py-8">No hay salas registradas aún.</p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nombre</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Capacidad</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Ubicación</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for room <- @rooms do %>
                      <tr>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm font-medium text-gray-900"><%= room.nombre %></div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-500"><%= room.capacidad %> personas</div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-500"><%= room.ubicacion %></div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <button 
                            phx-click="edit" 
                            phx-value-id={room.id}
                            class="text-indigo-600 hover:text-indigo-900 mr-3"
                          >
                            Editar
                          </button>
                          <button 
                            phx-click="delete" 
                            phx-value-id={room.id}
                            class="text-red-600 hover:text-red-900"
                            phx-confirm="¿Estás seguro de que deseas eliminar esta sala?"
                          >
                            Eliminar
                          </button>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
