defmodule YachanakuyWeb.Admin.PackageLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Tourism
  alias Yachanakuy.Tourism.Package

  on_mount {YachanakuyWeb.UserAuth, :mount_current_user}
  on_mount {YachanakuyWeb.UserAuth, :ensure_admin}

  def mount(_params, _session, socket) do
    package_list = Tourism.list_packages()
    changeset = Tourism.change_package(%Package{})

    socket = assign(socket,
      package_list: package_list,
      changeset: changeset,
      editing_package: nil,
      page: "admin_packages",
      success_message: nil
    )

    {:ok, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    package = Tourism.get_package!(String.to_integer(id))
    {:ok, _} = Tourism.delete_package(package)

    package_list = Tourism.list_packages()
    changeset = Tourism.change_package(%Package{})

    {:noreply,
     socket
     |> assign(:package_list, package_list)
     |> assign(:changeset, changeset)
     |> assign(:editing_package, nil)
     |> assign(:success_message, "Paquete eliminado exitosamente.")
    }
  end

  def handle_event("edit", %{"id" => id}, socket) do
    package = Tourism.get_package!(String.to_integer(id))
    changeset = Tourism.change_package(package)

    {:noreply, assign(socket,
      changeset: changeset,
      editing_package: package
    )}
  end

  def handle_event("cancel", _params, socket) do
    changeset = Tourism.change_package(%Package{})

    {:noreply, assign(socket,
      changeset: changeset,
      editing_package: nil
    )}
  end

  def handle_info({:save_package, {_component_pid, _action, package_params}}, socket) do
    result = if socket.assigns.editing_package do
      Tourism.update_package(socket.assigns.editing_package, package_params)
    else
      Tourism.create_package(package_params)
    end

    case result do
      {:ok, _package} ->
        package_list = Tourism.list_packages()
        changeset = Tourism.change_package(%Package{})

        socket = assign(socket,
          package_list: package_list,
          changeset: changeset,
          editing_package: nil,
          success_message: if(socket.assigns.editing_package, do: "Paquete actualizado", else: "Paquete creado") <> " exitosamente"
        )

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Paquetes</h1>

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
              <%= if @editing_package, do: "Editar Paquete", else: "Nuevo Paquete" %>
            </h2>

            <.live_component
              module={YachanakuyWeb.Admin.PackageFormComponent}
              id={if @editing_package, do: "package_form_#{@editing_package.id}", else: "package_form_new"}
              changeset={@changeset}
              action={if @editing_package, do: :edit, else: :new}
            />

            <%= if @editing_package do %>
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

        <!-- Lista de Paquetes -->
        <div class="lg:col-span-2">
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Lista de Paquetes</h2>

            <%= if @package_list == [] do %>
              <p class="text-gray-500 text-center py-8">No hay paquetes registrados aún.</p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Título</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Descripción</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for package <- @package_list do %>
                      <tr>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm font-medium text-gray-900"><%= package.titulo %></div>
                        </td>
                        <td class="px-6 py-4">
                          <div class="text-sm text-gray-500 max-w-xs truncate">
                            <%= if package.descripcion do %>
                              <%= String.slice(package.descripcion, 0..50) %><%= if String.length(package.descripcion || "") > 50, do: "..." %>
                            <% else %>
                              <span class="italic text-gray-400">Sin descripción</span>
                            <% end %>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <button
                            phx-click="edit"
                            phx-value-id={package.id}
                            class="text-indigo-600 hover:text-indigo-900 mr-3"
                          >
                            Editar
                          </button>
                          <button
                            phx-click="delete"
                            phx-value-id={package.id}
                            class="text-red-600 hover:text-red-900"
                            phx-confirm="¿Estás seguro de que deseas eliminar este paquete?"
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