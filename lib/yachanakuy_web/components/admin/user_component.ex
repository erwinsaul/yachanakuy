defmodule YachanakuyWeb.Admin.UserFormComponent do
  use YachanakuyWeb, :live_component

  @impl true
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
            field={f[:email]}
            type="email"
            label="Email *"
            placeholder="usuario@ejemplo.com"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
          />
        </div>

        <div>
          <.input
            field={f[:nombre_completo]}
            type="text"
            label="Nombre Completo *"
            placeholder="Nombre completo del usuario"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
          />
        </div>

        <div>
          <.input
            field={f[:rol]}
            type="select"
            label="Rol *"
            options={[
              {"Administrador", "admin"},
              {"Encargado de Comisión", "encargado_comision"},
              {"Operador", "operador"}
            ]}
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
          />
        </div>

        <div>
          <.input
            field={f[:activo]}
            type="checkbox"
            label="¿Activo?"
          />
        </div>

        <%= if @action == :new do %>
          <div>
            <.input
              field={f[:password]}
              type="password"
              label="Contraseña *"
              placeholder="Contraseña segura (mínimo 12 caracteres)"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
            />
          </div>

          <div>
            <.input
              field={f[:password_confirmation]}
              type="password"
              label="Confirmar Contraseña *"
              placeholder="Confirmar contraseña"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
            />
          </div>
        <% else %>
          <details class="border border-gray-200 rounded-md p-4">
            <summary class="cursor-pointer text-sm font-medium text-gray-700">Cambiar Contraseña (opcional)</summary>
            <div class="mt-4 space-y-4">
              <div>
                <.input
                  field={f[:password]}
                  type="password"
                  label="Nueva Contraseña"
                  placeholder="Dejar en blanco para mantener la contraseña actual"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>

              <div>
                <.input
                  field={f[:password_confirmation]}
                  type="password"
                  label="Confirmar Nueva Contraseña"
                  placeholder="Confirmar nueva contraseña"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
            </div>
          </details>
        <% end %>

        <div class="pt-4">
          <button
            type="submit"
            class="w-full bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded-md transition duration-300"
          >
            <%= if @action == :new, do: "Crear Usuario", else: "Actualizar Usuario" %>
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    send(self(), {:save_user, {socket.assigns.myself, socket.assigns.action, user_params}})
    {:noreply, socket}
  end
end