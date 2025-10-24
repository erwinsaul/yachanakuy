defmodule YachanakuyWeb.Admin.TouristInfoFormComponent do
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
            placeholder="Título del lugar turístico"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
          />
        </div>

        <div>
          <.input
            field={f[:descripcion]}
            type="textarea"
            label="Descripción"
            placeholder="Descripción del lugar turístico"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] h-32"
          />
        </div>

        <div>
          <.input
            field={f[:direccion]}
            type="text"
            label="Dirección"
            placeholder="Dirección del lugar turístico"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
          />
        </div>

        <div>
          <.input
            field={f[:imagen]}
            type="text"
            label="URL de Imagen"
            placeholder="https://ejemplo.com/imagen.jpg"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
          />
        </div>

        <div>
          <.input
            field={f[:estado]}
            type="select"
            label="Estado *"
            options={[
              {"Borrador", "borrador"},
              {"Publicado", "publicado"},
              {"Activo", "activo"},
              {"Inactivo", "inactivo"},
              {"Finalizado", "finalizado"}
            ]}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
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

  def handle_event("save", %{"tourist_info" => tourist_info_params}, socket) do
    send(self(), {:save_tourist_info, {socket.assigns.myself, socket.assigns.action, tourist_info_params}})
    {:noreply, socket}
  end
end