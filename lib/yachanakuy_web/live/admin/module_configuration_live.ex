defmodule YachanakuyWeb.Admin.ModuleConfigurationLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Settings
  alias Yachanakuy.Settings.ModuleConfiguration

  on_mount {YachanakuyWeb.UserAuth, :mount_current_user}
  on_mount {YachanakuyWeb.UserAuth, :ensure_admin}

  def mount(_params, _session, socket) do
    # Create default configurations if they don't exist
    create_default_configurations()
    
    module_config_list = Settings.list_module_configurations()
    changeset = Settings.change_module_configuration(%ModuleConfiguration{})

    socket = assign(socket,
      module_config_list: module_config_list,
      changeset: changeset,
      editing_module_config: nil,
      page: "admin_module_config",
      success_message: nil
    )

    {:ok, socket}
  end

  defp create_default_configurations do
    modules = ["attendees", "speakers", "sessions", "rooms", "commissions", "event_info", "tourist_info", "packages"]
    
    for module_name <- modules do
      case Settings.get_module_configuration_by_name(module_name) do
        nil -> 
          Settings.create_module_configuration(%{module_name: module_name, enabled: true})
        _ -> 
          nil
      end
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    module_config = Settings.get_module_configuration!(String.to_integer(id))
    {:ok, _} = Settings.delete_module_configuration(module_config)

    module_config_list = Settings.list_module_configurations()
    changeset = Settings.change_module_configuration(%ModuleConfiguration{})

    {:noreply,
     socket
     |> assign(:module_config_list, module_config_list)
     |> assign(:changeset, changeset)
     |> assign(:editing_module_config, nil)
     |> assign(:success_message, "Configuración de módulo eliminada exitosamente.")
    }
  end

  def handle_event("edit", %{"id" => id}, socket) do
    module_config = Settings.get_module_configuration!(String.to_integer(id))
    changeset = Settings.change_module_configuration(module_config)

    {:noreply, assign(socket,
      changeset: changeset,
      editing_module_config: module_config
    )}
  end

  def handle_event("cancel", _params, socket) do
    changeset = Settings.change_module_configuration(%ModuleConfiguration{})

    {:noreply, assign(socket,
      changeset: changeset,
      editing_module_config: nil
    )}
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    module_config = Settings.get_module_configuration!(String.to_integer(id))
    new_enabled_value = not module_config.enabled
    Settings.update_module_configuration(module_config, %{enabled: new_enabled_value})

    module_config_list = Settings.list_module_configurations()

    {:noreply,
     socket
     |> assign(:module_config_list, module_config_list)
     |> assign(:success_message, "Estado del módulo actualizado exitosamente.")
    }
  end

  def handle_info({:save_module_configuration, {_component_pid, _action, module_config_params}}, socket) do
    result = if socket.assigns.editing_module_config do
      Settings.update_module_configuration(socket.assigns.editing_module_config, module_config_params)
    else
      Settings.create_module_configuration(module_config_params)
    end

    case result do
      {:ok, _module_config} ->
        module_config_list = Settings.list_module_configurations()
        changeset = Settings.change_module_configuration(%ModuleConfiguration{})

        socket = assign(socket,
          module_config_list: module_config_list,
          changeset: changeset,
          editing_module_config: nil,
          success_message: if(socket.assigns.editing_module_config, do: "Configuración actualizada", else: "Configuración creada") <> " exitosamente"
        )

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Configuración de Módulos</h1>

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
              <%= if @editing_module_config, do: "Editar Configuración", else: "Nueva Configuración" %>
            </h2>

            <.live_component
              module={YachanakuyWeb.Admin.ModuleConfigurationFormComponent}
              id={if @editing_module_config, do: "module_config_form_#{@editing_module_config.id}", else: "module_config_form_new"}
              changeset={@changeset}
              action={if @editing_module_config, do: :edit, else: :new}
            />

            <%= if @editing_module_config do %>
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

        <!-- Lista de Configuraciones -->
        <div class="lg:col-span-2">
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Módulos del Sistema</h2>

            <%= if @module_config_list == [] do %>
              <p class="text-gray-500 text-center py-8">No hay configuraciones registradas aún.</p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Módulo</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for module_config <- @module_config_list do %>
                      <tr>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm font-medium text-gray-900">
                            <%= humanize_module_name(module_config.module_name) %>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span class={
                            "px-2 inline-flex text-xs leading-5 font-semibold rounded-full " <>
                            if module_config.enabled do
                              "bg-green-100 text-green-800"
                            else
                              "bg-red-100 text-red-800"
                            end
                          }>
                            <%= if module_config.enabled, do: "Habilitado", else: "Deshabilitado" %>
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <button
                            phx-click="toggle"
                            phx-value-id={module_config.id}
                            class={
                              if module_config.enabled do
                                "text-red-600 hover:text-red-900"
                              else
                                "text-green-600 hover:text-green-900"
                              end
                            }
                          >
                            <%= if module_config.enabled, do: "Deshabilitar", else: "Habilitar" %>
                          </button>
                          <button
                            phx-click="edit"
                            phx-value-id={module_config.id}
                            class="ml-3 text-indigo-600 hover:text-indigo-900"
                          >
                            Editar
                          </button>
                          <button
                            phx-click="delete"
                            phx-value-id={module_config.id}
                            class="ml-3 text-red-600 hover:text-red-900"
                            phx-confirm="¿Estás seguro de que deseas eliminar esta configuración?"
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

  defp humanize_module_name("attendees"), do: "Participantes"
  defp humanize_module_name("speakers"), do: "Expositores"
  defp humanize_module_name("sessions"), do: "Sesiones"
  defp humanize_module_name("rooms"), do: "Salas"
  defp humanize_module_name("commissions"), do: "Comisiones"
  defp humanize_module_name("event_info"), do: "Información del Evento"
  defp humanize_module_name("tourist_info"), do: "Información Turística"
  defp humanize_module_name("packages"), do: "Paquetes"
  defp humanize_module_name(name), do: String.capitalize(name)
end