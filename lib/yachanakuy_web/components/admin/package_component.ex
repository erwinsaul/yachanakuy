defmodule YachanakuyWeb.Admin.PackageFormComponent do
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
            field={f[:titulo]}
            type="text"
            label="Título *"
            placeholder="Título del paquete"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
          />
        </div>

        <div>
          <.input
            field={f[:descripcion]}
            type="textarea"
            label="Descripción"
            placeholder="Descripción del paquete"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] h-32"
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

  def handle_event("save", %{"package" => package_params}, socket) do
    send(self(), {:save_package, {socket.assigns.myself, socket.assigns.action, package_params}})
    {:noreply, socket}
  end
end