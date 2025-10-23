defmodule YachanakuyWeb.Admin.EventInfoLive do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Events
  alias Yachanakuy.Events.EventInfo

  on_mount {YachanakuyWeb.UserAuth, :mount_current_user}
  on_mount {YachanakuyWeb.UserAuth, :ensure_admin}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Información del Evento")}
  end

  def handle_params(params, _url, socket) do
    case params do
      %{"id" => _id, "action" => "new"} ->
        changeset = Events.change_event_info(%EventInfo{})
        
        {:noreply,
         socket
         |> assign(:event_info, nil)
         |> assign(:changeset, changeset)
         |> assign(:page_title, "Nueva Información del Evento")
         |> assign(:action, :new)}

      %{"id" => id, "action" => "edit"} ->
        event_info = Events.get_event_info!(String.to_integer(id))
        changeset = Events.change_event_info(event_info)
        
        {:noreply,
         socket
         |> assign(:event_info, event_info)
         |> assign(:changeset, changeset)
         |> assign(:page_title, "Editar Información del Evento")
         |> assign(:action, :edit)}

      %{"id" => id} ->
        event_info = Events.get_event_info!(String.to_integer(id))
        
        {:noreply,
         socket
         |> assign(:event_info, event_info)
         |> assign(:page_title, event_info.titulo)
         |> assign(:action, :show)}

      _ ->
        event_info_list = Events.list_event_info()
        
        {:noreply,
         socket
         |> assign(:event_info_list, event_info_list)
         |> assign(:page_title, "Información del Evento")
         |> assign(:action, :index)}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    event_info = Events.get_event_info!(String.to_integer(id))
    {:ok, _} = Events.delete_event_info(event_info)

    event_info_list = Events.list_event_info()

    {:noreply,
     socket
     |> put_flash(:info, "Información del evento eliminada exitosamente.")
     |> assign(:event_info_list, event_info_list)}
  end

  def handle_event("save", %{"event_info" => event_info_params}, socket) do
    case socket.assigns.action do
      :new ->
        case Events.create_event_info(event_info_params) do
          {:ok, _event_info} ->
            event_info_list = Events.list_event_info()

            {:noreply,
             socket
             |> put_flash(:info, "Información del evento creada exitosamente.")
             |> assign(:event_info_list, event_info_list)
             |> assign(:action, :index)}

          {:error, changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      :edit ->
        event_info = socket.assigns.event_info

        case Events.update_event_info(event_info, event_info_params) do
          {:ok, updated_event_info} ->
            {:noreply,
             socket
             |> put_flash(:info, "Información del evento actualizada exitosamente.")
             |> assign(:event_info, updated_event_info)
             |> assign(:action, :show)}

          {:error, changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end
    end
  end

  def handle_info({:save_event_info, {_component_pid, action, event_info_params}}, socket) do
    # Handle the form submission from the component
    case action do
      :new ->
        case Events.create_event_info(event_info_params) do
          {:ok, _event_info} ->
            event_info_list = Events.list_event_info()

            {:noreply,
             socket
             |> put_flash(:info, "Información del evento creada exitosamente.")
             |> assign(:event_info_list, event_info_list)
             |> assign(:action, :index)}

          {:error, changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      :edit ->
        event_info = socket.assigns.event_info

        case Events.update_event_info(event_info, event_info_params) do
          {:ok, updated_event_info} ->
            {:noreply,
             socket
             |> put_flash(:info, "Información del evento actualizada exitosamente.")
             |> assign(:event_info, updated_event_info)
             |> assign(:action, :show)}

          {:error, changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold text-[#144D85]"><%= @page_title %></h1>
        <%= if @action == :index do %>
          <.link 
            href={~p"/admin/event_info/new"} 
            class="inline-block bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded transition duration-300"
          >
            Nueva Información
          </.link>
        <% else %>
          <.link 
            href={~p"/admin/event_info"} 
            class="inline-block bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded transition duration-300"
          >
            Volver al listado
          </.link>
        <% end %>
      </div>

      <div class="bg-white shadow-md rounded-lg overflow-hidden">
        <%= case @action do %>
          <% :index -> %>
            <div>
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Título</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Activo</th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <%= for event_info <- @event_info_list do %>
                    <tr>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm font-medium text-gray-900"><%= event_info.titulo %></div>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span class={
                          "px-2 inline-flex text-xs leading-5 font-semibold rounded-full " <>
                          case event_info.estado do
                            "activo" -> "bg-green-100 text-green-800"
                            "publicado" -> "bg-blue-100 text-blue-800"
                            "inactivo" -> "bg-yellow-100 text-yellow-800"
                            "finalizado" -> "bg-gray-100 text-gray-800"
                            "borrador" -> "bg-purple-100 text-purple-800"
                            _ -> "bg-red-100 text-red-800"
                          end
                        }>
                          <%= event_info.estado %>
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <%= if event_info.activo, do: "Sí", else: "No" %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                        <.link href={~p"/admin/event_info/#{event_info.id}"} class="text-indigo-600 hover:text-indigo-900 mr-3">Ver</.link>
                        <.link href={~p"/admin/event_info/#{event_info.id}/edit"} class="text-indigo-600 hover:text-indigo-900 mr-3">Editar</.link>
                        <.link 
                          phx-click={JS.push("js-flash", value: %{info: "Eliminando...", color: "blue"})}
                          phx-value-id={event_info.id}
                          phx-submit="delete" 
                          data-confirm="¿Está seguro que desea eliminar esta información del evento?" 
                          class="text-red-600 hover:text-red-900"
                        >
                          Eliminar
                        </.link>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>

              <%= if Enum.empty?(@event_info_list) do %>
                <div class="text-center py-8">
                  <p class="text-gray-500">No hay información del evento registrada aún.</p>
                  <.link href={~p"/admin/event_info/new"} class="mt-4 inline-block bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded transition duration-300">
                    Crear la primera información
                  </.link>
                </div>
              <% end %>
            </div>

          <% :show -> %>
            <div class="p-6">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                <div>
                  <h3 class="text-lg font-semibold text-gray-700 mb-2">Título</h3>
                  <p class="text-gray-900"><%= @event_info.titulo %></p>
                </div>
                <div>
                  <h3 class="text-lg font-semibold text-gray-700 mb-2">Estado</h3>
                  <span class={
                    "px-2 inline-flex text-xs leading-5 font-semibold rounded-full " <>
                    case @event_info.estado do
                      "activo" -> "bg-green-100 text-green-800"
                      "publicado" -> "bg-blue-100 text-blue-800"
                      "inactivo" -> "bg-yellow-100 text-yellow-800"
                      "finalizado" -> "bg-gray-100 text-gray-800"
                      "borrador" -> "bg-purple-100 text-purple-800"
                      _ -> "bg-red-100 text-red-800"
                    end
                  }>
                    <%= @event_info.estado %>
                  </span>
                </div>
                <div>
                  <h3 class="text-lg font-semibold text-gray-700 mb-2">¿Activo?</h3>
                  <p class="text-gray-900"><%= if @event_info.activo, do: "Sí", else: "No" %></p>
                </div>
                <div>
                  <h3 class="text-lg font-semibold text-gray-700 mb-2">Fecha de creación</h3>
                  <p class="text-gray-900"><%= @event_info.inserted_at %></p>
                </div>
                <div>
                  <h3 class="text-lg font-semibold text-gray-700 mb-2">Última actualización</h3>
                  <p class="text-gray-900"><%= @event_info.updated_at %></p>
                </div>
                <div>
                  <h3 class="text-lg font-semibold text-gray-700 mb-2">Imagen</h3>
                  <%= if @event_info.imagen do %>
                    <img src={@event_info.imagen} alt={@event_info.titulo} class="max-w-full h-auto rounded-md">
                  <% else %>
                    <p class="text-gray-500 italic">No hay imagen disponible</p>
                  <% end %>
                </div>
              </div>

              <div class="mb-6">
                <h3 class="text-lg font-semibold text-gray-700 mb-2">Descripción</h3>
                <p class="text-gray-900 whitespace-pre-line"><%= @event_info.descripcion || "No hay descripción disponible" %></p>
              </div>

              <div class="flex space-x-4">
                <.link 
                  href={~p"/admin/event_info/#{@event_info.id}/edit"} 
                  class="bg-[#144D85] hover:bg-[#0d3a66] text-white font-bold py-2 px-4 rounded transition duration-300"
                >
                  Editar
                </.link>
                <.link 
                  phx-click={JS.push("js-flash", value: %{info: "Eliminando...", color: "blue"})}
                  phx-value-id={@event_info.id}
                  phx-submit="delete"
                  data-confirm="¿Está seguro que desea eliminar esta información del evento?" 
                  class="bg-red-500 hover:bg-red-600 text-white font-bold py-2 px-4 rounded transition duration-300"
                >
                  Eliminar
                </.link>
                <.link 
                  href={~p"/admin/event_info"} 
                  class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded transition duration-300"
                >
                  Volver al listado
                </.link>
              </div>
            </div>

          <% :new -> %>
            <div class="p-6">
              <.live_component 
                module={YachanakuyWeb.Admin.EventInfoFormComponent}
                id="event_info_form_new"
                changeset={@changeset}
                action={:new}
              />
            </div>

          <% :edit -> %>
            <div class="p-6">
              <.live_component 
                module={YachanakuyWeb.Admin.EventInfoFormComponent}
                id={"event_info_form_#{assigns.event_info.id}"}
                changeset={@changeset}
                action={:edit}
              />
            </div>
        <% end %>
      </div>
    </div>
    """
  end
end