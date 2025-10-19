defmodule YachanakuyWeb.Admin.SpeakerLive do
  use YachanakuyWeb, :live_view
  alias Yachanakuy.Program

  def mount(_params, _session, socket) do
    speakers = Program.list_speakers_with_sessions()
    
    changeset = Program.change_speaker(%Yachanakuy.Program.Speaker{})
    
    socket = assign(socket,
      speakers: speakers,
      changeset: changeset,
      editing_speaker: nil,
      page: "admin_speakers",
      success_message: nil
    )

    {:ok, socket}
  end

	def handle_event("save", %{"speaker" => speaker_params}, socket) do
	  result = if socket.assigns.editing_speaker do
	    Program.update_speaker(socket.assigns.editing_speaker, speaker_params)
	  else
	    Program.create_speaker(speaker_params)
	  end

	  case result do
	    {:ok, _speaker} ->
	      speakers = Program.list_speakers_with_sessions()
	      changeset = Program.change_speaker(%Yachanakuy.Program.Speaker{})
	      
	      socket = assign(socket,
	        speakers: speakers,
	        changeset: changeset,
	        editing_speaker: nil,
	        success_message: if(socket.assigns.editing_speaker, do: "Expositor actualizado", else: "Expositor creado") <> " exitosamente"
	      )
	      {:noreply, socket}

	    {:error, %Ecto.Changeset{} = changeset} ->
	      socket = assign(socket, changeset: changeset)
	      {:noreply, socket}
	  end
	end
  def handle_event("edit", %{"id" => id}, socket) do
    speaker = Program.get_speaker!(String.to_integer(id))
    changeset = Program.change_speaker(speaker)
    
    socket = assign(socket, 
      changeset: changeset,
      editing_speaker: speaker
    )
    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    speaker = Program.get_speaker!(String.to_integer(id))
    {:ok, _} = Program.delete_speaker(speaker)

    speakers = Program.list_speakers_with_sessions()
    changeset = Program.change_speaker(%Yachanakuy.Program.Speaker{})
    
    socket = assign(socket, 
      speakers: speakers, 
      changeset: changeset,
      editing_speaker: nil,
      success_message: "Expositor eliminado exitosamente"
    )
    {:noreply, socket}
  end

  def handle_event("cancel", _params, socket) do
    changeset = Program.change_speaker(%Yachanakuy.Program.Speaker{})
    
    socket = assign(socket, 
      changeset: changeset,
      editing_speaker: nil
    )
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Expositores</h1>
      
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
              <%= if @editing_speaker, do: "Editar Expositor", else: "Nuevo Expositor" %>
            </h2>
            
            <.form
              :let={f}
              for={@changeset}
              phx-submit="save"
              class="space-y-4"
            >
              <div>
                <.input field={f[:nombre_completo]} type="text" label="Nombre Completo"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div>
                <.input field={f[:institucion]} type="text" label="Institución"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div>
                <.input field={f[:email]} type="email" label="Email"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div>
                <.input field={f[:foto]} type="text" label="URL de Foto" placeholder="https://ejemplo.com/foto.jpg"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
              
              <div>
                <.input field={f[:biografia]} type="textarea" label="Biografía"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] h-32"
                />
              </div>
              
              <div class="flex space-x-3 pt-4">
                <button 
                  type="submit" 
                  class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded-md flex-1 transition duration-300"
                >
                  <%= if @editing_speaker, do: "Actualizar", else: "Crear" %>
                </button>
                
                <%= if @editing_speaker do %>
                  <button 
                    phx-click="cancel"
                    type="button"
                    class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-md flex-1 transition duration-300"
                  >
                    Cancelar
                  </button>
                <% end %>
              </div>
            </.form>
          </div>
        </div>
        
        <!-- Lista de Expositores -->
        <div class="lg:col-span-2">
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Lista de Expositores</h2>
            
            <%= if @speakers == [] do %>
              <p class="text-gray-500 text-center py-8">No hay expositores registrados aún.</p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nombre</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Institución</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for speaker <- @speakers do %>
                      <tr>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm font-medium text-gray-900"><%= speaker.nombre_completo %></div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-500"><%= speaker.institucion %></div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-500"><%= speaker.email %></div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <button 
                            phx-click="edit" 
                            phx-value-id={speaker.id}
                            class="text-indigo-600 hover:text-indigo-900 mr-3"
                          >
                            Editar
                          </button>
                          <button 
                            phx-click="delete" 
                            phx-value-id={speaker.id}
                            class="text-red-600 hover:text-red-900"
                            phx-confirm="¿Estás seguro de que deseas eliminar este expositor?"
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
