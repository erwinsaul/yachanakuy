defmodule YachanakuyWeb.Admin.SessionLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Program

  def mount(_params, _session, socket) do
    sessions = Program.list_sessions_with_details()
    speakers = Program.list_speakers_with_sessions()
    rooms = Program.list_rooms()
    
    changeset = Program.change_session(%Yachanakuy.Program.Session{})
    
    socket = assign(socket,
      sessions: sessions,
      speakers: speakers,
      rooms: rooms,
      changeset: changeset,
      editing_session: nil,
      page: "admin_sessions",
      success_message: nil
    )

    {:ok, socket}
  end

  def handle_event("save", %{"session" => session_params}, socket) do
    result = if socket.assigns.editing_session do
      Program.update_session(socket.assigns.editing_session, session_params)
    else
      Program.create_session(session_params)
    end
  
    case result do
      {:ok, _session} ->
        sessions = Program.list_sessions_with_details()
        speakers = Program.list_speakers_with_sessions()
        rooms = Program.list_rooms()
        changeset = Program.change_session(%Yachanakuy.Program.Session{})
        
        socket = assign(socket,
          sessions: sessions,
          speakers: speakers,
          rooms: rooms,
          changeset: changeset,
          editing_session: nil,
          success_message: if(socket.assigns.editing_session, do: "Sesión actualizada", else: "Sesión creada") <> " exitosamente"
        )
        {:noreply, socket}
  
      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def handle_event("edit", %{"id" => id}, socket) do
    session = Program.get_session!(String.to_integer(id))
    changeset = Program.change_session(session)
    
    socket = assign(socket, 
      changeset: changeset,
      editing_session: session
    )
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    session = Program.get_session!(String.to_integer(id))
    {:ok, _} = Program.delete_session(session)

    sessions = Program.list_sessions_with_details()
    speakers = Program.list_speakers_with_sessions()
    rooms = Program.list_rooms()
    changeset = Program.change_session(%Yachanakuy.Program.Session{})
    
    socket = assign(socket, 
      sessions: sessions,
      speakers: speakers,
      rooms: rooms,
      changeset: changeset,
      editing_session: nil,
      success_message: "Sesión eliminada exitosamente"
    )
    {:noreply, socket}
  end

  def handle_event("cancel", _params, socket) do
    changeset = Program.change_session(%Yachanakuy.Program.Session{})
    
    socket = assign(socket, 
      changeset: changeset,
      editing_session: nil
    )
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Gestión de Sesiones</h1>
      
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
              <%= if @editing_session, do: "Editar Sesión", else: "Nueva Sesión" %>
            </h2>
            
            <.form
              :let={f}
              for={@changeset}
              phx-submit="save"
              class="space-y-4"
            >
              <div>
                <.input field={f[:titulo]} type="text" label="Título"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div>
                <.input field={f[:descripcion]} type="textarea" label="Descripción"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] h-24"
                />
              </div>
              
              <div>
                <.input field={f[:tipo]} type="select" label="Tipo"
                  options={[{"Conferencia", "conferencia"}, {"Taller", "taller"}, {"Receso", "receso"}, {"Plenaria", "plenaria"}]}
                  prompt="Selecciona un tipo"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div>
                <.input field={f[:fecha]} type="date" label="Fecha"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <.input field={f[:hora_inicio]} type="time" label="Hora Inicio"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                  />
                </div>
                
                <div>
                  <.input field={f[:hora_fin]} type="time" label="Hora Fin"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                  />
                </div>
              </div>
              
              <div>
                <.input field={f[:speaker_id]} type="select" label="Expositor"
                  options={[nil: "No asignado"] ++ for speaker <- @speakers, do: {speaker.nombre_completo, speaker.id}}
                  prompt="Seleccione un Expositor"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div>
                <.input field={f[:room_id]} type="select" label="Sala"
                  options={ Enum.map(@rooms, fn room -> {room.nombre, room.id} end) }
                  prompt="Selecciona una sala"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div class="pt-4">
                <button 
                  type="submit" 
                  class="w-full bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded-md transition duration-300"
                >
                  <%= if @editing_session, do: "Actualizar", else: "Crear" %>
                </button>
                
                <%= if @editing_session do %>
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
        
        <!-- Lista de Sesiones -->
        <div class="lg:col-span-2">
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Lista de Sesiones</h2>
            
            <%= if @sessions == [] do %>
              <p class="text-gray-500 text-center py-8">No hay sesiones registradas aún.</p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Título</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Fecha</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Hora</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Sala</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Expositor</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for session <- @sessions do %>
                      <tr>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm font-medium text-gray-900"><%= session.titulo %></div>
                          <div class="text-sm text-gray-500"><%= session.tipo %></div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-500">
                            <%= Timex.format!(Timex.to_datetime(session.fecha), "{0D}/{0M}/{YYYY}") %>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-500">
                            <%= Time.to_string(session.hora_inicio) %> - <%= Time.to_string(session.hora_fin) %>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-500"><%= if session.room, do: session.room.nombre, else: "No asignada" %></div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-500"><%= if session.speaker, do: session.speaker.nombre_completo, else: "No asignado" %></div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <button 
                            phx-click="edit" 
                            phx-value-id={session.id}
                            class="text-indigo-600 hover:text-indigo-900 mr-3"
                          >
                            Editar
                          </button>
                          <button 
                            phx-click="delete" 
                            phx-value-id={session.id}
                            class="text-red-600 hover:text-red-900"
                            phx-confirm="¿Estás seguro de que deseas eliminar esta sesión?"
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
