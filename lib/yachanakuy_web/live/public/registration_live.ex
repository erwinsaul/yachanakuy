defmodule YachanakuyWeb.Public.RegistrationLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Registration
  alias Yachanakuy.Events
  alias Yachanakuy.Uploads.Handler

  def mount(_params, _session, socket) do
    # Verificar si las inscripciones están abiertas
    settings = Events.get_congress_settings()

    if settings && !settings.inscripciones_abiertas do
      socket = assign(socket, error: "Las inscripciones no están abiertas en este momento.")
      {:ok, socket}
    else
      categories = Events.list_attendee_categories()

      changeset = Registration.change_attendee(%Yachanakuy.Registration.Attendee{})

      socket = socket
      |> assign(
        changeset: changeset,
        categories: categories,
        settings: settings,
        page: "inscripcion",
        error: nil
      )
      |> allow_upload(:foto,
        accept: ~w(.jpg .jpeg .png .gif .webp),
        max_file_size: 5_000_000
      )
      |> allow_upload(:comprobante_pago,
        accept: ~w(.jpg .jpeg .png .pdf),
        max_file_size: 10_000_000
      )

      {:ok, socket}
    end
  end

  def handle_event("save", %{"attendee" => attendee_params}, socket) do
    # Procesar uploads de archivos
    {foto_path, socket} = process_upload(socket, :foto, "fotos")
    {comprobante_pago_path, socket} = process_upload(socket, :comprobante_pago, "comprobantes")

    # Agregar las rutas de archivos al params
    attendee_params = 
      attendee_params
      |> Map.put("foto", foto_path)
      |> Map.put("comprobante_pago", comprobante_pago_path)

    case Registration.create_attendee(attendee_params) do
      {:ok, _attendee} ->
        # Aquí iría la lógica para generar QR, token de descarga, etc.
        # Por ahora solo redirigimos con un mensaje de éxito

        socket = put_flash(socket, :info, "¡Inscripción completada exitosamente! Revisa tu correo para más instrucciones.")
        {:noreply, push_navigate(socket, to: "/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        socket = assign(socket, changeset: changeset)
        {:noreply, socket}
    end
  end

  # Función para procesar uploads de archivos
  defp process_upload(socket, field, upload_type) do
    case consume_uploaded_entries(socket, field, fn _meta, entry ->
          # Procesar archivo con el handler de uploads
          case upload_type do
            "fotos" -> 
              Handler.upload_image(%{filename: Path.basename(entry.client_name), path: entry.path}, "foto")
            "comprobantes" -> 
              Handler.upload_document(%{filename: Path.basename(entry.client_name), path: entry.path}, "comprobante_pago")
            _ -> 
              {:error, "Tipo de archivo no válido"}
          end
        end) do
      {[file_path], socket} -> {file_path, socket}
      {[], socket} -> {nil, socket}  # No files were uploaded
      _ -> {nil, socket}  # Error occurred
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8 max-w-3xl">
      <%= if @error do %>
        <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6">
          <%= @error %>
        </div>
      <% else %>
        <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Formulario de Inscripción</h1>

        <div class="bg-white rounded-lg shadow-md p-6">
          <.form
            :let={f}
            for={@changeset}
            phx-submit="save"
            class="space-y-4"
          >
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <.input field={f[:nombre_completo]} type="text" label="Nombre completo" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]" />
              </div>

              <div>
                <.input field={f[:numero_documento]} type="text" label="Número de documento" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]" />
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <.input field={f[:email]} type="email" label="Email" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]" />
              </div>

              <div>
                <.input field={f[:telefono]} type="text" label="Teléfono" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]" />
              </div>
            </div>

            <div>
              <.input field={f[:institucion]} type="text" label="Institución" class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]" />
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <.input 
                  field={f[:category_id]} 
                  type="select" 
                  label="Categoría de participante"
                  options={[{"Selecciona una categoría", nil}] ++ Enum.map(@categories, fn cat -> {cat.nombre, cat.id} end)}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>

              <div>
                <.input 
                  field={f[:estado]} 
                  type="select" 
                  label="Estado"
                  options={[{"Pendiente", "pendiente_revision"}]}
                  value="pendiente_revision"
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
                />
              </div>
            </div>

            <div>
              <label class="block text-gray-700 font-medium mb-2">Foto</label>
              <.live_file_input upload={@uploads.foto} 
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
              />
              <p class="text-sm text-gray-500 mt-1">Sube una foto clara de tu rostro (JPG, PNG, máximo 5MB)</p>
              <div :for={err <- upload_errors(@uploads.foto)} class="text-sm text-red-600 mt-1"><%= err %></div>
            </div>

            <div>
              <label class="block text-gray-700 font-medium mb-2">Comprobante de pago</label>
              <.live_file_input upload={@uploads.comprobante_pago} 
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85]"
              />
              <p class="text-sm text-gray-500 mt-1">Adjunta el comprobante de pago (JPG, PNG, PDF, máximo 10MB)</p>
              <div :for={err <- upload_errors(@uploads.comprobante_pago)} class="text-sm text-red-600 mt-1"><%= err %></div>
            </div>

            <div class="pt-4">
              <button
                type="submit"
                class="w-full bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-3 px-4 rounded-md transition duration-300"
              >
                Completar Inscripción
              </button>
            </div>
          </.form>
        </div>
      <% end %>
    </div>
    """
  end
end
