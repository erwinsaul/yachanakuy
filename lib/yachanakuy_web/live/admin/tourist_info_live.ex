defmodule YachanakuyWeb.Admin.TouristInfoLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Tourism
  alias Yachanakuy.Tourism.TouristInfo

  on_mount {YachanakuyWeb.UserAuth, :mount_current_user}
  on_mount {YachanakuyWeb.UserAuth, :ensure_admin}

  def mount(_params, _session, socket) do
    tourist_info_list = Tourism.list_tourist_info()
    changeset = Tourism.change_tourist_info(%TouristInfo{})

    socket = assign(socket,
      tourist_info_list: tourist_info_list,
      changeset: changeset,
      editing_tourist_info: nil,
      page: "admin_tourist_info",
      success_message: nil
    )

    {:ok, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    tourist_info = Tourism.get_tourist_info!(String.to_integer(id))
    {:ok, _} = Tourism.delete_tourist_info(tourist_info)

    tourist_info_list = Tourism.list_tourist_info()
    changeset = Tourism.change_tourist_info(%TouristInfo{})

    {:noreply,
     socket
     |> assign(:tourist_info_list, tourist_info_list)
     |> assign(:changeset, changeset)
     |> assign(:editing_tourist_info, nil)
     |> assign(:success_message, "Información turística eliminada exitosamente.")
    }
  end

  def handle_event("edit", %{"id" => id}, socket) do
    tourist_info = Tourism.get_tourist_info!(String.to_integer(id))
    changeset = Tourism.change_tourist_info(tourist_info)

    {:noreply, assign(socket,
      changeset: changeset,
      editing_tourist_info: tourist_info
    )}
  end

  def handle_event("cancel", _params, socket) do
    changeset = Tourism.change_tourist_info(%TouristInfo{})

    {:noreply, assign(socket,
      changeset: changeset,
      editing_tourist_info: nil
    )}
  end

  def handle_info({:save_tourist_info, {_component_pid, _action, tourist_info_params}}, socket) do
    result = if socket.assigns.editing_tourist_info do
      Tourism.update_tourist_info(socket.assigns.editing_tourist_info, tourist_info_params)
    else
      Tourism.create_tourist_info(tourist_info_params)
    end

    case result do
      {:ok, _tourist_info} ->
        tourist_info_list = Tourism.list_tourist_info()
        changeset = Tourism.change_tourist_info(%TouristInfo{})

        socket = assign(socket,
          tourist_info_list: tourist_info_list,
          changeset: changeset,
          editing_tourist_info: nil,
          success_message: if(socket.assigns.editing_tourist_info, do: "Información turística actualizada", else: "Información turística creada") <> " exitosamente"
        )

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Información Turística</h1>

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
              <%= if @editing_tourist_info, do: "Editar Información Turística", else: "Nueva Información Turística" %>
            </h2>

            <.live_component
              module={YachanakuyWeb.Admin.TouristInfoFormComponent}
              id={if @editing_tourist_info, do: "tourist_info_form_#{@editing_tourist_info.id}", else: "tourist_info_form_new"}
              changeset={@changeset}
              action={if @editing_tourist_info, do: :edit, else: :new}
            />

            <%= if @editing_tourist_info do %>
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

        <!-- Lista de Información Turística -->
        <div class="lg:col-span-2">
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Lista de Información Turística</h2>

            <%= if @tourist_info_list == [] do %>
              <p class="text-gray-500 text-center py-8">No hay información turística registrada aún.</p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Título</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Descripción</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Dirección</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for tourist_info <- @tourist_info_list do %>
                      <tr>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm font-medium text-gray-900"><%= tourist_info.titulo %></div>
                        </td>
                        <td class="px-6 py-4">
                          <div class="text-sm text-gray-500 max-w-xs truncate">
                            <%= if tourist_info.descripcion do %>
                              <%= String.slice(tourist_info.descripcion, 0..50) %><%= if String.length(tourist_info.descripcion || "") > 50, do: "..." %>
                            <% else %>
                              <span class="italic text-gray-400">Sin descripción</span>
                            <% end %>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm text-gray-500">
                            <%= if tourist_info.direccion do %>
                              <%= String.slice(tourist_info.direccion, 0..30) %><%= if String.length(tourist_info.direccion) > 30, do: "..." %>
                            <% else %>
                              <span class="italic text-gray-400">Sin dirección</span>
                            <% end %>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span class={
                            "px-2 inline-flex text-xs leading-5 font-semibold rounded-full " <>
                            case tourist_info.estado do
                              "activo" -> "bg-green-100 text-green-800"
                              "publicado" -> "bg-blue-100 text-blue-800"
                              "inactivo" -> "bg-yellow-100 text-yellow-800"
                              "finalizado" -> "bg-gray-100 text-gray-800"
                              "borrador" -> "bg-purple-100 text-purple-800"
                              _ -> "bg-red-100 text-red-800"
                            end
                          }>
                            <%= String.capitalize(tourist_info.estado) %>
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <button
                            phx-click="edit"
                            phx-value-id={tourist_info.id}
                            class="text-indigo-600 hover:text-indigo-900 mr-3"
                          >
                            Editar
                          </button>
                          <button
                            phx-click="delete"
                            phx-value-id={tourist_info.id}
                            class="text-red-600 hover:text-red-900"
                            phx-confirm="¿Estás seguro de que deseas eliminar esta información turística?"
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