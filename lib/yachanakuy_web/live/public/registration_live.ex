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

      socket = socket
      |> assign(
        current_step: 1,
        registration_data: %{
          institucion: "",
          comprobante_pago: nil,
          cantidad_personas: 1,
          participantes: []
        },
        categories: categories,
        settings: settings,
        page: "inscripcion",
        error: nil,
        errors: %{},  # Nuevo: para almacenar errores por campo
        success: nil,
        uploaded_file_name: nil  # Para mostrar el archivo seleccionado
      )
      |> allow_upload(:comprobante_pago,
        accept: ~w(.jpg .jpeg .png .pdf),
        max_entries: 1,
        max_file_size: 10_000_000,
        auto_upload: true,  # Activar auto-upload
        progress: &handle_progress/3  # Manejar progreso
      )

      {:ok, socket}
    end
  end

  # Manejar progreso de subida
  defp handle_progress(:comprobante_pago, entry, socket) do
    IO.puts("=== PROGRESO DE SUBIDA ===")
    IO.inspect(entry, label: "Entry")

    if entry.done? do
      IO.puts("Archivo completado, consumiendo...")

      # Consumir el archivo inmediatamente
      consumed = consume_uploaded_entries(socket, :comprobante_pago, fn meta, entry ->
        IO.puts("Guardando archivo: #{entry.client_name}")
        IO.inspect(meta, label: "Meta info")
        result = Handler.upload_document(%{filename: Path.basename(entry.client_name), path: meta.path}, "comprobante_pago")
        IO.inspect(result, label: "Resultado de upload_document")
        result
      end)

      IO.inspect(consumed, label: "Resultado de consume_uploaded_entries")

      case consumed do
        [path | _] when is_binary(path) ->
          IO.puts("✓ Archivo guardado exitosamente en: #{path}")
          registration_data = socket.assigns.registration_data
          updated_registration_data = Map.put(registration_data, :comprobante_pago, path)

          {:noreply,
           socket
           |> assign(registration_data: updated_registration_data)
           |> assign(uploaded_file_name: entry.client_name)}
        [] ->
          IO.puts("✗ Error: consume_uploaded_entries retornó lista vacía")
          {:noreply, socket}
        other ->
          IO.puts("✗ Error: formato inesperado")
          IO.inspect(other, label: "Valor recibido")
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("next_step", _params, socket) do
    current_step = socket.assigns.current_step

    case current_step do
      1 ->
        # Validar Paso 1 - registrar errores por campo
        registration_data = socket.assigns.registration_data
        field_errors = validate_step1_field_errors(registration_data, socket)

        if map_size(field_errors) == 0 do
          # Si no hay errores, avanzar al siguiente paso
          new_step = current_step + 1
          socket = assign(socket, current_step: new_step, errors: %{})  # Limpiar errores
          {:noreply, socket}
        else
          # Si hay errores, mantener en el mismo paso y mostrar errores por campo
          socket = assign(socket, errors: field_errors)
          {:noreply, socket}
        end
      2 ->
        # Validar Paso 2 - registrar errores por campo
        registration_data = socket.assigns.registration_data
        field_errors = validate_step2_field_errors(registration_data)
        uniqueness_errors = validate_uniqueness_errors(registration_data)

        # Combinar todos los errores
        all_errors = Map.merge(field_errors, uniqueness_errors)

        if map_size(all_errors) == 0 do
          new_step = current_step + 1
          socket = assign(socket, current_step: new_step, errors: %{})  # Limpiar errores
          {:noreply, socket}
        else
          # Si hay errores, mantener en el mismo paso y mostrar errores por campo
          socket = assign(socket, errors: all_errors)
          {:noreply, socket}
        end
      _ ->
        new_step = current_step + 1
        socket = assign(socket, current_step: new_step)
        {:noreply, socket}
    end
  end

  def handle_event("prev_step", _params, socket) do
    current_step = socket.assigns.current_step
    new_step = max(1, current_step - 1)

    socket = assign(socket, current_step: new_step)

    {:noreply, socket}
  end

  # Evento unificado que maneja cambios en el formulario y uploads
  def handle_event("validate", params, socket) do
    registration_data = socket.assigns.registration_data

    # Si hay parámetros de registration, actualizar los datos
    updated_registration_data = if Map.has_key?(params, "registration") do
      reg_params = params["registration"]

      # Validar y limitar cantidad de personas (min: 1, max: 50)
      new_cantidad_personas = case Integer.parse(Map.get(reg_params, "cantidad_personas", "1")) do
        {num, _} when num >= 1 and num <= 50 -> num
        {num, _} when num < 1 -> 1
        {num, _} when num > 50 -> 50
        :error -> 1
      end

      updated = registration_data
        |> Map.put(:institucion, Map.get(reg_params, "institucion", ""))
        |> Map.put(:cantidad_personas, new_cantidad_personas)

      # Ajustar la longitud de la lista de participantes según la cantidad, preservando datos existentes
      participantes = adjust_participantes_list(updated.participantes, new_cantidad_personas)
      Map.put(updated, :participantes, participantes)
    else
      registration_data
    end

    # Procesar archivo si se completó la subida
    socket = assign(socket, registration_data: updated_registration_data)

    completed_entries = Enum.filter(socket.assigns.uploads.comprobante_pago.entries, fn entry -> entry.done? end)

    socket = if length(completed_entries) > 0 do
      # Consumir el archivo inmediatamente y guardarlo
      case consume_uploaded_entries(socket, :comprobante_pago, fn (entry, _entry_data) ->
        IO.puts("Consumiendo archivo: #{entry.client_name}")
        Handler.upload_document(%{filename: Path.basename(entry.client_name), path: entry.path}, "comprobante_pago")
      end) do
        [{:ok, path} | _] ->
          IO.puts("Archivo guardado en: #{path}")
          registration_data = socket.assigns.registration_data
          updated_registration_data = Map.put(registration_data, :comprobante_pago, path)
          assign(socket, registration_data: updated_registration_data)
        _ ->
          IO.puts("No se pudo guardar el archivo")
          socket
      end
    else
      socket
    end

    {:noreply, socket}
  end

  def handle_event("update_registration_data", %{"registration" => params}, socket) do
    registration_data = socket.assigns.registration_data

    # Validar y limitar cantidad de personas (min: 1, max: 50)
    new_cantidad_personas = case Integer.parse(Map.get(params, "cantidad_personas", "1")) do
      {num, _} when num >= 1 and num <= 50 -> num
      {num, _} when num < 1 -> 1
      {num, _} when num > 50 -> 50
      :error -> 1
    end

    updated_registration_data =
      registration_data
      |> Map.put(:institucion, Map.get(params, "institucion", ""))
      |> Map.put(:cantidad_personas, new_cantidad_personas)

    # Ajustar la longitud de la lista de participantes según la cantidad, preservando datos existentes
    participantes = adjust_participantes_list(updated_registration_data.participantes, new_cantidad_personas)

    updated_registration_data = Map.put(updated_registration_data, :participantes, participantes)

    socket = assign(socket, registration_data: updated_registration_data)

    {:noreply, socket}
  end

  # Manejar validación y procesamiento del upload del comprobante
  def handle_event("validate_comprobante", _params, socket) do
    IO.puts("=== VALIDANDO COMPROBANTE ===")

    # Verificar si hay archivos completados para consumir
    completed_entries = Enum.filter(socket.assigns.uploads.comprobante_pago.entries, fn entry -> entry.done? end)

    IO.inspect(completed_entries, label: "Archivos completados")

    socket = if length(completed_entries) > 0 do
      # Consumir el archivo inmediatamente y guardarlo
      case consume_uploaded_entries(socket, :comprobante_pago, fn (entry, _entry_data) ->
        IO.puts("Consumiendo archivo: #{entry.client_name}")
        Handler.upload_document(%{filename: Path.basename(entry.client_name), path: entry.path}, "comprobante_pago")
      end) do
        [{:ok, path} | _] ->
          IO.puts("Archivo guardado en: #{path}")
          registration_data = socket.assigns.registration_data
          updated_registration_data = Map.put(registration_data, :comprobante_pago, path)

          assign(socket, registration_data: updated_registration_data)
        _ ->
          IO.puts("No se pudo guardar el archivo")
          socket
      end
    else
      IO.puts("No hay archivos completados todavía")
      socket
    end

    {:noreply, socket}
  end

  def handle_event("update_participante_data", %{"participante_index" => index_str, "participante" => params}, socket) do
    index = String.to_integer(index_str)

    # Convertir category_id a integer si no está vacío
    category_id = case Map.get(params, "category_id", "") |> String.trim() do
      "" -> nil
      id_str ->
        case Integer.parse(id_str) do
          {id_int, _} -> id_int
          :error -> nil
        end
    end

    participante_data = %{
      nombre_completo: Map.get(params, "nombre_completo", "") |> String.trim(),
      numero_documento: Map.get(params, "numero_documento", "") |> String.trim(),
      email: Map.get(params, "email", "") |> String.trim(),
      telefono: Map.get(params, "telefono", "") |> String.trim(),
      foto: Map.get(params, "foto", "") |> String.trim(),
      category_id: category_id
    }

    registration_data = socket.assigns.registration_data

    # Asegurar que la lista tiene suficientes elementos y actualizar el participante en el índice especificado
    current_participantes = adjust_participantes_list(registration_data.participantes, max(length(registration_data.participantes), index + 1))

    updated_participantes =
      Enum.map(Enum.with_index(current_participantes), fn {existing_participante, idx} ->
        if idx == index do
          participante_data
        else
          existing_participante
        end
      end)

    updated_registration_data = Map.put(registration_data, :participantes, updated_participantes)

    socket = assign(socket, registration_data: updated_registration_data)

    {:noreply, socket}
  end

  def handle_event("register_attendees", _params, socket) do
    IO.puts("=== INICIO REGISTRO ===")

    # Verificar si hay archivos subidos y completados
    uploaded_entries = socket.assigns.uploads.comprobante_pago.entries
    IO.inspect(uploaded_entries, label: "Uploaded entries")

    completed_uploads = Enum.filter(uploaded_entries, fn entry -> entry.done? end)
    pending_uploads = Enum.filter(uploaded_entries, fn entry -> !entry.done? && entry.progress > 0 end)

    IO.inspect(length(completed_uploads), label: "Completed uploads")
    IO.inspect(length(pending_uploads), label: "Pending uploads")
    IO.inspect(socket.assigns.registration_data.comprobante_pago, label: "Comprobante previo")

    cond do
      # Hay uploads en progreso
      length(pending_uploads) > 0 ->
        IO.puts("CASO 1: Hay uploads pendientes")
        socket = assign(socket,
          error: "Por favor espere a que el comprobante de pago se suba completamente antes de registrar."
        )
        {:noreply, socket}

      # Hay uploads completados, procesarlos
      length(completed_uploads) > 0 ->
        IO.puts("CASO 2: Procesando uploads completados")
        # Procesar el comprobante de pago
        comprobante_pago_path = case consume_uploaded_entries(socket, :comprobante_pago, fn (entry, _entry_data) ->
          Handler.upload_document(%{filename: Path.basename(entry.client_name), path: entry.path}, "comprobante_pago")
        end) do
          [{:ok, path} | _] -> path
          _ -> nil
        end

        if is_nil(comprobante_pago_path) do
          IO.puts("ERROR: No se pudo procesar el comprobante")
          socket = assign(socket,
            error: "Error al procesar el comprobante de pago. Por favor, inténtelo de nuevo."
          )
          {:noreply, socket}
        else
          IO.puts("OK: Comprobante procesado, llamando a process_registration")
          process_registration(socket, comprobante_pago_path)
        end

      # No hay uploads pero puede haber uno previamente guardado
      true ->
        IO.puts("CASO 3: Buscando comprobante previamente guardado")
        comprobante_pago_path = socket.assigns.registration_data.comprobante_pago

        if is_nil(comprobante_pago_path) do
          IO.puts("ERROR: No hay comprobante de pago")
          socket = assign(socket,
            error: "El comprobante de pago es obligatorio. Por favor, suba un archivo."
          )
          {:noreply, socket}
        else
          IO.puts("OK: Comprobante encontrado, llamando a process_registration")
          process_registration(socket, comprobante_pago_path)
        end
    end
  end

  defp has_comprobante_pago?(socket) do
    # Verificar si el archivo ya fue guardado (lo más importante)
    comprobante_pago = socket.assigns.registration_data.comprobante_pago

    # El archivo está guardado si comprobante_pago tiene una ruta
    if comprobante_pago && comprobante_pago != "" do
      true
    else
      # Si no está guardado, verificar si hay entradas en proceso
      length(socket.assigns.uploads.comprobante_pago.entries) > 0
    end
  end

  # Consumir archivos pendientes solo si están completados
  defp _consume_pending_uploads(socket) do
    IO.puts("=== INTENTANDO CONSUMIR UPLOADS PENDIENTES ===")

    # Obtener todas las entradas
    entries = socket.assigns.uploads.comprobante_pago.entries

    IO.inspect(entries, label: "Todas las entradas")

    if length(entries) > 0 do
      # Verificar si hay entradas completadas
      completed_entries = Enum.filter(entries, fn entry -> entry.done? end)

      IO.inspect(length(completed_entries), label: "Entradas completadas")

      if length(completed_entries) > 0 do
        # Solo consumir si hay archivos completados
        consumed = consume_uploaded_entries(socket, :comprobante_pago, fn meta, entry ->
          IO.puts("Procesando entrada: #{entry.client_name}")
          IO.inspect(meta, label: "Meta")

          # El archivo temporal está en meta.path
          Handler.upload_document(%{filename: Path.basename(entry.client_name), path: meta.path}, "comprobante_pago")
        end)

        IO.inspect(consumed, label: "Archivos consumidos")

        case consumed do
          [{:ok, path} | _] ->
            IO.puts("Archivo guardado exitosamente en: #{path}")
            registration_data = socket.assigns.registration_data
            updated_registration_data = Map.put(registration_data, :comprobante_pago, path)
            assign(socket, registration_data: updated_registration_data)
          _ ->
            IO.puts("No se pudo consumir ningún archivo")
            socket
        end
      else
        IO.puts("Hay archivos seleccionados pero ninguno está completado (done?: false)")
        IO.puts("Esto puede deberse a que la conexión está usando longpoll en lugar de WebSocket")
        socket
      end
    else
      IO.puts("No hay entradas para consumir")
      socket
    end
  end



  defp validate_step1_field_errors(registration_data, socket) do
    errors = %{}

    # Validar institución
    errors = if registration_data.institucion == "" or is_nil(registration_data.institucion) do
      Map.put(errors, :institucion, "La institución es obligatoria")
    else
      errors
    end

    # Validar cantidad de personas
    errors = if registration_data.cantidad_personas <= 0 do
      Map.put(errors, :cantidad_personas, "La cantidad debe ser mayor a 0")
    else
      errors
    end

    # Validar comprobante de pago
    has_comprobante = has_comprobante_pago?(socket)
    IO.puts("=== VALIDANDO COMPROBANTE ===")
    IO.inspect(registration_data.comprobante_pago, label: "Comprobante en registration_data")
    IO.inspect(length(socket.assigns.uploads.comprobante_pago.entries), label: "Entradas en upload")
    IO.inspect(has_comprobante, label: "Tiene comprobante?")

    errors = if not has_comprobante do
      Map.put(errors, :comprobante_pago, "El comprobante de pago es obligatorio")
    else
      errors
    end

    errors
  end

  defp validate_step2_field_errors(registration_data) do
    required_fields = [:nombre_completo, :numero_documento, :email, :category_id]

    # Validar solo los participantes según la cantidad especificada
    participantes_a_validar = Enum.take(registration_data.participantes, registration_data.cantidad_personas)

    # Validar cada participante y acumular errores
    participantes_a_validar
    |> Enum.with_index
    |> Enum.reduce(%{}, fn {participante, index}, acc_errors ->
      # Verificar si el participante existe y tiene campos
      if participante && is_map(participante) do
        # Validar todos los campos requeridos (siempre, no solo si has_some_data)
        missing_fields = Enum.filter(required_fields, fn field ->
          value = Map.get(participante, field)
          is_nil(value) or value == "" or (is_binary(value) and String.trim(value) == "")
        end)

        # Validar formato de email si está presente
        email_errors = if participante.email && participante.email != "" do
          if valid_email_format?(participante.email) do
            []
          else
            [{:email, "Formato de email inválido"}]
          end
        else
          []
        end

        # Agregar errores para cada campo faltante
        acc_errors = Enum.reduce(missing_fields, acc_errors, fn field, inner_errors ->
          field_key = "participante_#{index}_#{field}" |> String.to_atom()
          error_msg = case field do
            :nombre_completo -> "Nombre completo es obligatorio"
            :numero_documento -> "Número de documento es obligatorio"
            :email -> "Email es obligatorio"
            :category_id -> "Categoría es obligatoria"
            _ -> "Este campo es obligatorio"
          end
          Map.put(inner_errors, field_key, error_msg)
        end)

        # Agregar errores de formato de email
        Enum.reduce(email_errors, acc_errors, fn {field, msg}, inner_errors ->
          field_key = "participante_#{index}_#{field}" |> String.to_atom()
          Map.put(inner_errors, field_key, msg)
        end)
      else
        # Si el participante no existe, registrar errores para todos los campos requeridos
        Enum.reduce(required_fields, acc_errors, fn field, inner_errors ->
          field_key = "participante_#{index}_#{field}" |> String.to_atom()
          error_msg = case field do
            :nombre_completo -> "Nombre completo es obligatorio"
            :numero_documento -> "Número de documento es obligatorio"
            :email -> "Email es obligatorio"
            :category_id -> "Categoría es obligatoria"
            _ -> "Este campo es obligatorio"
          end
          Map.put(inner_errors, field_key, error_msg)
        end)
      end
    end)
  end

  # Validar formato de email
  defp valid_email_format?(email) do
    Regex.match?(~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, email)
  end

  # Traducir errores de upload a mensajes legibles
  defp translate_upload_error(:too_large), do: "El archivo es demasiado grande (máximo 10MB)"
  defp translate_upload_error(:not_accepted), do: "Tipo de archivo no permitido (solo JPG, PNG, PDF)"
  defp translate_upload_error(:too_many_files), do: "Solo se permite un archivo"
  defp translate_upload_error(error), do: "Error al subir archivo: #{error}"

  # Validar unicidad de email y documento
  defp validate_uniqueness_errors(registration_data) do
    participantes_a_validar = Enum.take(registration_data.participantes, registration_data.cantidad_personas)

    participantes_a_validar
    |> Enum.with_index
    |> Enum.reduce(%{}, fn {participante, index}, acc_errors ->
      acc_errors = if participante.email && participante.email != "" do
        case Registration.get_attendee_by_email(participante.email) do
          nil -> acc_errors
          _attendee ->
            field_key = "participante_#{index}_email" |> String.to_atom()
            Map.put(acc_errors, field_key, "Este email ya está registrado")
        end
      else
        acc_errors
      end

      if participante.numero_documento && participante.numero_documento != "" do
        case Registration.get_attendee_by_documento(participante.numero_documento) do
          nil -> acc_errors
          _attendee ->
            field_key = "participante_#{index}_numero_documento" |> String.to_atom()
            Map.put(acc_errors, field_key, "Este documento ya está registrado")
        end
      else
        acc_errors
      end
    end)
  end

  defp adjust_participantes_list(participantes, cantidad_personas) do
    current_length = length(participantes)

    if current_length < cantidad_personas do
      # Agregar participantes vacíos al final, preservando los datos existentes
      empty_participante = %{
        nombre_completo: "",
        numero_documento: "",
        email: "",
        telefono: "",
        foto: "",
        category_id: nil
      }
      participantes ++ List.duplicate(empty_participante, cantidad_personas - current_length)
    else
      # Quitar participantes extras del final, pero mantener solo los primeros 'cantidad_personas'
      Enum.take(participantes, cantidad_personas)
    end
  end

  defp process_registration(socket, comprobante_pago_path) do
    registration_data = socket.assigns.registration_data
    updated_registration_data = Map.put(registration_data, :comprobante_pago, comprobante_pago_path)

    # Registrar solo los participantes según la cantidad especificada
    participantes_a_registrar = Enum.take(updated_registration_data.participantes, updated_registration_data.cantidad_personas)

    # Log de debug
    IO.inspect(participantes_a_registrar, label: "Participantes a registrar")
    IO.inspect(comprobante_pago_path, label: "Comprobante de pago")

    results = for participante <- participantes_a_registrar do
      attendee_params = %{
        nombre_completo: participante.nombre_completo,
        numero_documento: participante.numero_documento,
        email: participante.email,
        telefono: participante.telefono || "",
        institucion: updated_registration_data.institucion,
        foto: participante.foto || "",
        category_id: participante.category_id,
        comprobante_pago: updated_registration_data.comprobante_pago,
        estado: "pendiente_revision"
      }

      IO.inspect(attendee_params, label: "Parámetros del participante")
      result = Registration.create_attendee(attendee_params)
      IO.inspect(result, label: "Resultado de create_attendee")
      result
    end

    IO.inspect(results, label: "Todos los resultados")

    # Verificar si todos se registraron correctamente
    case Enum.find(results, fn {status, _} -> status == :error end) do
      nil ->
        # Todos los registros fueron exitosos
        socket = socket
        |> assign(
          success: "¡Inscripciones completadas exitosamente! Revisa tu correo para más instrucciones.",
          current_step: nil
        )
        |> put_flash(:info, "¡Inscripciones completadas exitosamente! Revisa tu correo para más instrucciones.")

        {:noreply, push_navigate(socket, to: "/")}
      _ ->
        # Hubo al menos un error
        error_changeset =
          results
          |> Enum.find(fn {status, _} -> status == :error end)
          |> elem(1)

        # Generar mensaje de error más descriptivo
        error_message = case error_changeset do
          %Ecto.Changeset{errors: errors} ->
            error_details = errors
            |> Enum.map(fn {field, {msg, _}} -> "#{field}: #{msg}" end)
            |> Enum.join(", ")
            "Error al registrar participante: #{error_details}"
          _ ->
            "Hubo un error al registrar a uno o más participantes."
        end

        socket = assign(socket, error: error_message)
        {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-blue-900 to-indigo-900 py-8">
      <div class="container mx-auto px-4 py-8 max-w-4xl">
        <%= if @current_step do %>
          <div class="bg-white rounded-lg shadow-lg p-6">
            <!-- Indicador de pasos -->
            <div class="mb-8">
              <h1 class="text-3xl font-bold mb-2 text-[#144D85]">CCBOL 2025</h1>
              <h2 class="text-2xl font-semibold mb-4 text-[#144D85]">Formulario de Inscripción</h2>
              
              <!-- Barra de progreso -->
              <div class="flex items-center justify-between mb-6">
                <div class="flex flex-col items-center">
                  <div class={"w-8 h-8 rounded-full flex items-center justify-center " <> 
                    if(@current_step >= 1, do: "bg-[#144D85] text-white", else: "bg-gray-400 text-white")}>
                    1
                  </div>
                  <span class="text-xs mt-1 text-center text-white">Información General</span>
                </div>
                
                <div class="flex-1 h-1 bg-gray-400 mx-2">
                  <div class={"h-full " <> if(@current_step >= 2, do: "bg-[#144D85]", else: "bg-gray-400")}></div>
                </div>
                
                <div class="flex flex-col items-center">
                  <div class={"w-8 h-8 rounded-full flex items-center justify-center " <> 
                    if(@current_step >= 2, do: "bg-[#144D85] text-white", else: "bg-gray-400 text-white")}>
                    2
                  </div>
                  <span class="text-xs mt-1 text-center text-white">Datos de Participantes</span>
                </div>
                
                <div class="flex-1 h-1 bg-gray-400 mx-2">
                  <div class={"h-full " <> if(@current_step >= 3, do: "bg-[#144D85]", else: "bg-gray-400")}></div>
                </div>
                
                <div class="flex flex-col items-center">
                  <div class={"w-8 h-8 rounded-full flex items-center justify-center " <> 
                    if(@current_step >= 3, do: "bg-[#144D85] text-white", else: "bg-gray-400 text-white")}>
                    3
                  </div>
                  <span class="text-xs mt-1 text-center text-white">Resumen</span>
                </div>
              </div>
            </div>

            <!-- Contenido del paso actual -->
            <div class="step-content">
              <%= case @current_step do %>
                <% 1 -> %>
                  <%= render_step1(assigns) %>
                <% 2 -> %>
                  <%= render_step2(assigns) %>
                <% 3 -> %>
                  <%= render_step3(assigns) %>
              <% end %>
            </div>
          </div>
        <% else %>
          <!-- Vista de éxito -->
          <div class="bg-white rounded-lg shadow-lg p-6">
            <h1 class="text-3xl font-bold mb-4 text-[#144D85]">¡Inscripción completa!</h1>
            <p class="text-green-600">Tus participantes han sido registrados exitosamente.</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_step1(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Paso 1: Información General</h2>
      <p class="text-gray-600 mb-6">Por favor, completa la información general de la inscripción.</p>

      <form phx-change="validate" phx-submit="next_step" class="space-y-4">
        <div>
          <label class="block text-gray-700 font-medium mb-2">Institución <span class="text-red-500">*</span></label>
          <input
            type="text"
            name="registration[institucion]"
            value={@registration_data.institucion}
            class={"w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] text-gray-900 " <> if(Map.get(@errors, :institucion), do: "border-red-500", else: "border-gray-300")}
            required
          />
          <%= if error = Map.get(@errors, :institucion) do %>
            <p class="text-sm text-red-600 mt-1"><%= error %></p>
          <% end %>
        </div>

        <div>
          <label class="block text-gray-700 font-medium mb-2">Cantidad de personas a registrar <span class="text-red-500">*</span></label>
          <input
            type="number"
            name="registration[cantidad_personas]"
            value={@registration_data.cantidad_personas}
            min="1"
            max="50"
            class={"w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] text-gray-900 " <> if(Map.get(@errors, :cantidad_personas), do: "border-red-500", else: "border-gray-300")}
            required
          />
          <p class="text-sm text-gray-500 mt-1">Indica cuántas personas se registrarán en esta inscripción</p>
          <%= if error = Map.get(@errors, :cantidad_personas) do %>
            <p class="text-sm text-red-600 mt-1"><%= error %></p>
          <% end %>
        </div>

        <div class="mt-6">
          <label class="block text-gray-700 font-medium mb-2">Comprobante de pago <span class="text-red-500">*</span></label>
          <.live_file_input upload={@uploads.comprobante_pago}
            class={"w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] text-gray-900 " <> if(Map.get(@errors, :comprobante_pago), do: "border-red-500", else: "border-gray-300")}
          />
          <p class="text-sm text-gray-500 mt-1">Adjunta el comprobante de pago (JPG, PNG, PDF, máximo 10MB)</p>
          <%= if error = Map.get(@errors, :comprobante_pago) do %>
            <p class="text-sm text-red-600 mt-1"><%= error %></p>
          <% end %>
          <div :for={err <- upload_errors(@uploads.comprobante_pago)} class="text-sm text-red-600 mt-1"><%= translate_upload_error(err) %></div>

          <!-- Mostrar archivo seleccionado y progreso -->
          <div :for={entry <- @uploads.comprobante_pago.entries} class="mt-2">
            <%= if entry.progress < 100 do %>
              <div class="space-y-2">
                <div class="flex items-center gap-2">
                  <svg class="w-5 h-5 text-blue-600 animate-spin" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  <span class="text-sm text-gray-700 font-medium"><%= entry.client_name %></span>
                  <span class="text-sm text-blue-600">Subiendo... <%= entry.progress %>%</span>
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2">
                  <div class="bg-blue-600 h-2 rounded-full transition-all duration-300" style={"width: #{entry.progress}%"}></div>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Mensaje cuando ya está guardado -->
          <%= if @registration_data.comprobante_pago && @uploaded_file_name do %>
            <div class="mt-2 flex items-center gap-2 p-3 bg-green-50 border border-green-200 rounded-md">
              <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
              </svg>
              <div class="flex-1">
                <span class="text-sm text-green-700 font-medium">✓ Comprobante cargado correctamente</span>
                <p class="text-xs text-green-600"><%= @uploaded_file_name %></p>
              </div>
            </div>
          <% end %>
        </div>

        <div class="flex justify-end mt-8">
          <button
            type="button"
            phx-click="next_step"
            class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-6 rounded-md transition duration-300"
          >
            Siguiente
          </button>
        </div>
      </form>
    </div>
    """
  end

  defp render_step2(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Paso 2: Datos de los Participantes</h2>
      <p class="text-gray-600 mb-6">Ingresa los datos de las <%= @registration_data.cantidad_personas %> persona(s) a registrar.</p>
      
      <div class="space-y-6">
        <%= for {participante, index} <- Enum.with_index(@registration_data.participantes) do %>
          <div class="border border-gray-200 rounded-lg p-4 bg-gray-50">
            <h3 class="text-lg font-medium mb-3 text-[#144D85]">Participante <%= index + 1 %></h3>
            
            <form phx-change={"update_participante_data"} class="space-y-4">
              <input type="hidden" name="participante_index" value={index} />
              
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-gray-700 font-medium mb-2">Nombre completo <span class="text-red-500">*</span></label>
                  <input 
                    type="text" 
                    name="participante[nombre_completo]" 
                    value={participante.nombre_completo}
                    class={"w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] text-gray-900 " <> if(Map.get(@errors, String.to_atom("participante_#{index}_nombre_completo")), do: "border-red-500", else: "border-gray-300")}
                    required
                  />
                  <%= if error = Map.get(@errors, String.to_atom("participante_#{index}_nombre_completo")) do %>
                    <p class="text-sm text-red-600 mt-1"><%= error %></p>
                  <% end %>
                </div>

                <div>
                  <label class="block text-gray-700 font-medium mb-2">Número de documento <span class="text-red-500">*</span></label>
                  <input 
                    type="text" 
                    name="participante[numero_documento]" 
                    value={participante.numero_documento}
                    class={"w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] text-gray-900 " <> if(Map.get(@errors, String.to_atom("participante_#{index}_numero_documento")), do: "border-red-500", else: "border-gray-300")}
                    required
                  />
                  <%= if error = Map.get(@errors, String.to_atom("participante_#{index}_numero_documento")) do %>
                    <p class="text-sm text-red-600 mt-1"><%= error %></p>
                  <% end %>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-gray-700 font-medium mb-2">Email <span class="text-red-500">*</span></label>
                  <input 
                    type="email" 
                    name="participante[email]" 
                    value={participante.email}
                    class={"w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] text-gray-900 " <> if(Map.get(@errors, String.to_atom("participante_#{index}_email")), do: "border-red-500", else: "border-gray-300")}
                    required
                  />
                  <%= if error = Map.get(@errors, String.to_atom("participante_#{index}_email")) do %>
                    <p class="text-sm text-red-600 mt-1"><%= error %></p>
                  <% end %>
                  <p class="text-sm text-gray-500 mt-1">Es importante que proporciones un email válido, ya que allí recibirás tus credenciales y otros datos importantes.</p>
                </div>

                <div>
                  <label class="block text-gray-700 font-medium mb-2">Teléfono</label>
                  <input 
                    type="text" 
                    name="participante[telefono]" 
                    value={participante.telefono}
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] text-gray-900"
                  />
                </div>
              </div>

              <div>
                <label class="block text-gray-700 font-medium mb-2">Foto (opcional)</label>
                <input 
                  type="text" 
                  name="participante[foto]" 
                  value={participante.foto}
                  class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] text-gray-900"
                  placeholder="URL de la foto o dejar vacío"
                />
              </div>

              <div>
                <label class="block text-gray-700 font-medium mb-2">Categoría de participante <span class="text-red-500">*</span></label>
                <select 
                  name="participante[category_id]" 
                  class={"w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-[#144D85] text-gray-900 " <> if(Map.get(@errors, String.to_atom("participante_#{index}_category_id")), do: "border-red-500", else: "border-gray-300")}
                  value={participante.category_id}
                  required
                >
                  <option value="">Selecciona una categoría</option>
                  <%= for category <- @categories do %>
                    <option value={category.id} selected={participante.category_id == category.id}><%= category.nombre %></option>
                  <% end %>
                </select>
                <%= if error = Map.get(@errors, String.to_atom("participante_#{index}_category_id")) do %>
                  <p class="text-sm text-red-600 mt-1"><%= error %></p>
                <% end %>
              </div>
            </form>
          </div>
        <% end %>

        <div class="flex justify-between mt-8">
          <button
            type="button"
            phx-click="prev_step"
            class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-6 rounded-md transition duration-300"
          >
            Anterior
          </button>
          
          <button
            type="button"
            phx-click="next_step"
            class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-6 rounded-md transition duration-300"
          >
            Siguiente
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp render_step3(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Paso 3: Resumen y Confirmación</h2>
      <p class="text-gray-600 mb-6">Revisa los datos antes de completar la inscripción.</p>

      <div class="space-y-6">
        <div class="border border-gray-200 rounded-lg p-4">
          <h3 class="text-lg font-medium mb-3 text-[#144D85]">Información General</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p class="font-medium text-gray-700">Institución:</p>
              <p class="text-gray-900"><%= @registration_data.institucion %></p>
            </div>
            <div>
              <p class="font-medium text-gray-700">Número de participantes:</p>
              <p class="text-gray-900"><%= @registration_data.cantidad_personas %></p>
            </div>
          </div>
        </div>

        <%= for {participante, index} <- Enum.with_index(@registration_data.participantes) do %>
          <%= if index < @registration_data.cantidad_personas do %>
            <div class="border border-gray-200 rounded-lg p-4 bg-gray-50">
              <h3 class="text-lg font-medium mb-3 text-[#144D85]">Participante <%= index + 1 %></h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <p class="font-medium text-gray-700">Nombre completo:</p>
                  <p class="text-gray-900"><%= participante.nombre_completo || "No especificado" %></p>
                </div>
                <div>
                  <p class="font-medium text-gray-700">Número de documento:</p>
                  <p class="text-gray-900"><%= participante.numero_documento || "No especificado" %></p>
                </div>
                <div>
                  <p class="font-medium text-gray-700">Email:</p>
                  <p class="text-gray-900"><%= participante.email || "No especificado" %></p>
                </div>
                <div>
                  <p class="font-medium text-gray-700">Teléfono:</p>
                  <p class="text-gray-900"><%= if participante.telefono != "", do: participante.telefono, else: "No especificado" %></p>
                </div>
                <div>
                  <p class="font-medium text-gray-700">Categoría:</p>
                  <p class="text-gray-900">
                    <%= if participante.category_id do %>
                      <%= case Enum.find(@categories, fn c -> c.id == participante.category_id end) do %>
                        <% nil -> %>
                          No seleccionada
                        <% category -> %>
                          <%= category.nombre %>
                      <% end %>
                    <% else %>
                      No seleccionada
                    <% end %>
                  </p>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>

      <div class="flex justify-between mt-8">
        <button
          type="button"
          phx-click="prev_step"
          class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-6 rounded-md transition duration-300"
        >
          Anterior
        </button>
        
        <button
          type="button"
          phx-click="register_attendees"
          class="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded-md transition duration-300"
        >
          Registrar Participantes
        </button>
      </div>
    </div>
    """
  end

end