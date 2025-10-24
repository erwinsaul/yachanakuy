defmodule YachanakuyWeb.Admin.ModuleConfigurationFormComponent do
  use YachanakuyWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.form
        :let={f}
        for={@changeset}
        phx-target={@myself}
        phx-submit="save"
        class="space-y-4"
      >
        <div>
          <.input
            field={f[:module_name]}
            type="select"
            label="Nombre del Módulo *"
            options={[
              {"Participantes", "attendees"},
              {"Expositores", "speakers"}, 
              {"Sesiones", "sessions"},
              {"Salas", "rooms"},
              {"Comisiones", "commissions"},
              {"Información del Evento", "event_info"},
              {"Información Turística", "tourist_info"},
              {"Paquetes", "packages"}
            ]}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
          />
        </div>

        <div class="flex items-center">
          <.input
            field={f[:enabled]}
            type="checkbox"
            label="¿Habilitado?"
          />
        </div>

        <div class="pt-4">
          <button
            type="submit"
            class="w-full bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded-md transition duration-300"
          >
            <%= if @action == :new, do: "Crear", else: "Actualizar" %>
          </button>
        </div>
      </.form>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("save", %{"module_configuration" => module_configuration_params}, socket) do
    send(self(), {:save_module_configuration, {socket.assigns.myself, socket.assigns.action, module_configuration_params}})
    {:noreply, socket}
  end
end