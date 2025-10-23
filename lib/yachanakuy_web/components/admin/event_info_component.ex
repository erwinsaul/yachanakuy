defmodule YachanakuyWeb.Admin.EventInfoFormComponent do
  use YachanakuyWeb, :live_component

  def render(assigns) do
    ~H"""
    <.form
      for={@changeset}
      phx-target={@myself}
      phx-submit="save"
      class="space-y-6"
    >
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div class="form-group">
          <.input
            field={@changeset[:titulo]}
            type="text"
            label="Título *"
            placeholder="Título del evento"
          />
        </div>

        <div class="form-group">
          <.input
            field={@changeset[:estado]}
            type="select"
            label="Estado"
            prompt="Seleccione un estado"
            options={[borrador: "borrador", publicado: "publicado", activo: "activo", inactivo: "inactivo", finalizado: "finalizado"]}
          />
        </div>

        <div class="form-group md:col-span-2">
          <.input
            field={@changeset[:descripcion]}
            type="textarea"
            label="Descripción"
            placeholder="Descripción detallada del evento"
            rows="4"
          />
        </div>

        <div class="form-group">
          <.input
            field={@changeset[:imagen]}
            type="text"
            label="Imagen (URL)"
            placeholder="URL de la imagen del evento"
          />
        </div>

        <div class="form-group flex items-center">
          <.input
            field={@changeset[:activo]}
            type="checkbox"
            label="¿Activo?"
          />
        </div>
      </div>

      <div class="mt-6">
        <button type="submit" class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded transition duration-300 mr-2">
          <%= if @action == :new, do: "Crear", else: "Actualizar" %>
        </button>
        <.link href={~p"/admin/event_info"} class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded transition duration-300">
          Cancelar
        </.link>
      </div>
    </.form>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("save", %{"event_info" => event_info_params}, socket) do
    send(self(), {:save_event_info, {socket.assigns.myself, socket.assigns.action, event_info_params}})
    {:noreply, socket}
  end
end