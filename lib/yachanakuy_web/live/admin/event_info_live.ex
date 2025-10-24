defmodule YachanakuyWeb.Admin.EventInfoLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Events
  alias Yachanakuy.Events.EventInfo

  on_mount {YachanakuyWeb.UserAuth, :mount_current_user}
  on_mount {YachanakuyWeb.UserAuth, :ensure_admin}

  def mount(_params, _session, socket) do
    event_info_list = Events.list_event_info()
    changeset = Events.change_event_info(%EventInfo{})

    socket = assign(socket,
      event_info_list: event_info_list,
      changeset: changeset,
      editing_event_info: nil,
      page: "admin_event_info",
      success_message: nil
    )

    {:ok, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    event_info = Events.get_event_info!(String.to_integer(id))
    {:ok, _} = Events.delete_event_info(event_info)

    event_info_list = Events.list_event_info()
    changeset = Events.change_event_info(%EventInfo{})

    {:noreply,
     socket
     |> assign(:event_info_list, event_info_list)
     |> assign(:changeset, changeset)
     |> assign(:editing_event_info, nil)
     |> assign(:success_message, "Información del evento eliminada exitosamente.")}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    event_info = Events.get_event_info!(String.to_integer(id))
    changeset = Events.change_event_info(event_info)

    {:noreply, assign(socket,
      changeset: changeset,
      editing_event_info: event_info
    )}
  end

  def handle_event("cancel", _params, socket) do
    changeset = Events.change_event_info(%EventInfo{})

    {:noreply, assign(socket,
      changeset: changeset,
      editing_event_info: nil
    )}
  end

  def handle_info({:save_event_info, {_component_pid, action, event_info_params}}, socket) do
    result = if socket.assigns.editing_event_info do
      Events.update_event_info(socket.assigns.editing_event_info, event_info_params)
    else
      Events.create_event_info(event_info_params)
    end

    case result do
      {:ok, _event_info} ->
        event_info_list = Events.list_event_info()
        changeset = Events.change_event_info(%EventInfo{})

        socket = assign(socket,
          event_info_list: event_info_list,
          changeset: changeset,
          editing_event_info: nil,
          success_message: if(socket.assigns.editing_event_info, do: "Información del evento actualizada", else: "Información del evento creada") <> " exitosamente"
        )

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Información del Evento</h1>

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
              <%= if @editing_event_info, do: "Editar Información del Evento", else: "Nueva Información del Evento" %>
            </h2>

            <.live_component
              module={YachanakuyWeb.Admin.EventInfoFormComponent}
              id={if @editing_event_info, do: "event_info_form_#{@editing_event_info.id}", else: "event_info_form_new"}
              changeset={@changeset}
              action={if @editing_event_info, do: :edit, else: :new}
            />

            <%= if @editing_event_info do %>
              <button
                phx-click="cancel"
                type="button"
                class="w-full mt-4 bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-md transition duration-300"
              >
                Cancelar
              </button>
            <% end %>
          </div>
        </div>

        <!-- Lista de Información del Evento -->
        <div class="lg:col-span-2">
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Lista de Información del Evento</h2>

            <%= if @event_info_list == [] do %>
              <p class="text-gray-500 text-center py-8">No hay información del evento registrada aún.</p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Título</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Descripción</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Activo</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for event_info <- @event_info_list do %>
                      <tr>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm font-medium text-gray-900"><%= event_info.titulo %></div>
                        </td>
                        <td class="px-6 py-4">
                          <div class="text-sm text-gray-500 max-w-xs truncate">
                            <%= if event_info.descripcion do %>
                              <%= String.slice(event_info.descripcion, 0..50) %><%= if String.length(event_info.descripcion || "") > 50, do: "..." %>
                            <% else %>
                              <span class="italic text-gray-400">Sin descripción</span>
                            <% end %>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span class={
                            "px-2 inline-flex text-xs leading-5 font-semibold rounded-full " <>
                            case event_info.estado do
                              "activo" -> "bg-green-100 text-green-800"
                              "publicado" -> "bg-blue-100 text-blue-800"
                              "inactivo" -> "bg-yellow-100 text-yellow-800"
                              "finalizado" -> "bg-gray-100 text-gray-800"
                              "borrador" -> "bg-purple-100 text-purple-800"
                              _ -> "bg-red-100 text-red-800"
                            end
                          }>
                            <%= String.capitalize(event_info.estado) %>
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <%= if event_info.activo, do: "Sí", else: "No" %>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <button
                            phx-click="edit"
                            phx-value-id={event_info.id}
                            class="text-indigo-600 hover:text-indigo-900 mr-3"
                          >
                            Editar
                          </button>
                          <button
                            phx-click="delete"
                            phx-value-id={event_info.id}
                            class="text-red-600 hover:text-red-900"
                            phx-confirm="¿Estás seguro de que deseas eliminar esta información del evento?"
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