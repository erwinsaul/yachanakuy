defmodule YachanakuyWeb.Admin.SettingsLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Events

  def mount(_params, _session, socket) do
    settings = Events.get_congress_settings()

    changeset = if settings do
      Events.change_settings(settings)
    else
      Events.change_settings(%Yachanakuy.Events.Settings{})
    end

    socket = assign(socket,
      settings: settings,
      changeset: changeset,
      page: "admin_settings",
      success_message: nil
    )

    {:ok, socket}
  end

  def handle_event("save", %{"settings" => settings_params}, socket) do
    settings = socket.assigns.settings

    result = if settings do
      Events.update_settings(settings, settings_params)
    else
      Events.create_settings(settings_params)
    end

    case result do
      {:ok, settings} ->
        socket = assign(socket,
          settings: settings,
          changeset: Events.change_settings(settings),
          success_message: "Configuración actualizada exitosamente"
        )
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-6">
        <h1 class="text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white">Configuración del Congreso</h1>
        <p class="mt-2 text-gray-600 dark:text-gray-400">Gestiona la configuración general del evento</p>
      </div>

      <%= if @success_message do %>
        <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 text-green-800 dark:text-green-200 px-4 py-3 rounded-lg mb-6 flex items-start">
          <svg class="w-5 h-5 mr-3 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <span><%= @success_message %></span>
        </div>
      <% end %>

      <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <div class="flex items-center mb-6">
          <div class="p-2 rounded-lg bg-blue-100 dark:bg-blue-900/50 mr-4">
            <svg class="w-5 h-5 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
            </svg>
          </div>
          <h2 class="text-lg font-semibold text-gray-900 dark:text-white">Configuración General</h2>
        </div>

        <.form
          :let={f}
          for={@changeset}
          phx-submit="save"
          class="space-y-6"
        >
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <.input field={f[:nombre]} type="text" label="Nombre del Congreso"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 dark:text-white"
              />
            </div>

            <div>
              <.input field={f[:estado]} type="select" label="Estado del Congreso"
                options={[borrador: "Borrador", publicado: "Publicado", activo: "Activo", finalizado: "Finalizado"]}
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 dark:text-white"
              />
            </div>

            <div class="md:col-span-2">
              <.input field={f[:descripcion]} type="textarea" label="Descripción"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 dark:text-white h-32"
              />
            </div>

            <div>
              <.input field={f[:fecha_inicio]} type="date" label="Fecha de Inicio"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 dark:text-white"
              />
            </div>

            <div>
              <.input field={f[:fecha_fin]} type="date" label="Fecha de Finalización"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 dark:text-white"
              />
            </div>

            <div class="md:col-span-2">
              <.input field={f[:ubicacion]} type="text" label="Ubicación"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 dark:text-white"
              />
            </div>

            <div class="md:col-span-2">
              <.input field={f[:direccion_evento]} type="textarea" label="Dirección Completa del Evento"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 dark:text-white h-24"
              />
            </div>

            <div class="md:col-span-2">
              <.input field={f[:logo]} type="text" label="URL del Logo" placeholder="https://ejemplo.com/logo.png"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 dark:text-white"
              />
            </div>

            <div class="md:col-span-2">
              <.input field={f[:inscripciones_abiertas]} type="checkbox" label="Inscripciones Abiertas"
                class="h-5 w-5 text-blue-600 dark:text-blue-400 transition duration-150 ease-in-out rounded focus:ring-blue-500 dark:focus:ring-blue-400"
              />
            </div>

            <div class="md:col-span-2">
              <.input field={f[:info_turismo]} type="textarea" label="Información Turística" placeholder="Información turística de la ciudad sede..."
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500 text-gray-900 dark:text-white h-32"
              />
            </div>
          </div>

          <div class="pt-6">
            <button
              type="submit"
              class="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-lg transition-colors duration-200"
            >
              Guardar Configuración
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
