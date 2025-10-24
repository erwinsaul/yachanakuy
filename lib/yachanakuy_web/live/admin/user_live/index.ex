defmodule YachanakuyWeb.Admin.UserLive.Index do
  use YachanakuyWeb, :live_view

  alias Yachanakuy.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-8 text-[#144D85]">Gestión de Usuarios</h1>

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
              <%= if @editing_user, do: "Editar Usuario", else: "Nuevo Usuario" %>
            </h2>

            <.live_component
              module={YachanakuyWeb.Admin.UserFormComponent}
              id={if @editing_user, do: "user_form_#{@editing_user.id}", else: "user_form_new"}
              changeset={@changeset}
              action={if @editing_user, do: :edit, else: :new}
            />

            <%= if @editing_user do %>
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

        <!-- Lista de Usuarios -->
        <div class="lg:col-span-2">
          <div class="bg-white rounded-lg shadow-md p-6">
            <h2 class="text-xl font-semibold mb-4 text-[#144D85]">Lista de Usuarios</h2>

            <%= if @users == [] do %>
              <p class="text-gray-500 text-center py-8">No hay usuarios registrados aún.</p>
            <% else %>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nombre Completo</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Rol</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-200">
                    <%= for user <- @users do %>
                      <tr>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <div class="text-sm font-medium text-gray-900"><%= user.email %></div>
                        </td>
                        <td class="px-6 py-4">
                          <div class="text-sm text-gray-500 max-w-xs truncate">
                            <%= if user.nombre_completo do %>
                              <%= String.slice(user.nombre_completo, 0..30) %><%= if String.length(user.nombre_completo || "") > 30, do: "..." %>
                            <% else %>
                              <span class="italic text-gray-400">Sin nombre</span>
                            <% end %>
                          </div>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span class={
                            "px-2 inline-flex text-xs leading-5 font-semibold rounded-full " <>
                            case user.rol do
                              "admin" -> "bg-purple-100 text-purple-800"
                              "encargado_comision" -> "bg-blue-100 text-blue-800"
                              "operador" -> "bg-green-100 text-green-800"
                              _ -> "bg-gray-100 text-gray-800"
                            end
                          }>
                            <%= case user.rol do %>
                              <% "admin" -> %>Administrador
                              <% "encargado_comision" -> %>Encargado
                              <% "operador" -> %>Operador
                              <% _ -> %>Desconocido
                            <% end %>
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap">
                          <span class={
                            "px-2 inline-flex text-xs leading-5 font-semibold rounded-full " <>
                            if user.activo do
                              "bg-green-100 text-green-800"
                            else
                              "bg-red-100 text-red-800"
                            end
                          }>
                            <%= if user.activo, do: "Activo", else: "Inactivo" %>
                          </span>
                        </td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                          <button
                            phx-click="edit"
                            phx-value-id={user.id}
                            class="text-indigo-600 hover:text-indigo-900 mr-3"
                          >
                            Editar
                          </button>
                          <button
                            phx-click="reset_password"
                            phx-value-id={user.id}
                            class="text-orange-600 hover:text-orange-900 mr-3"
                            phx-confirm="¿Está seguro de que desea restablecer la contraseña de este usuario?"
                          >
                            Restablecer Contraseña
                          </button>
                          <button
                            phx-click="delete"
                            phx-value-id={user.id}
                            class="text-red-600 hover:text-red-900"
                            phx-confirm="¿Estás seguro de que deseas eliminar este usuario?"
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

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.list_users()
    changeset = Accounts.change_user_registration(%Yachanakuy.Accounts.User{}, %{})

    socket = assign(socket,
      users: users,
      changeset: changeset,
      editing_user: nil,
      page: "admin_users",
      success_message: nil
    )

    {:ok, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(String.to_integer(id))
    {:ok, _} = Accounts.delete_user(user)

    users = Accounts.list_users()
    changeset = Accounts.change_user_registration(%Yachanakuy.Accounts.User{}, %{})

    {:noreply,
     socket
     |> assign(:users, users)
     |> assign(:changeset, changeset)
     |> assign(:editing_user, nil)
     |> assign(:success_message, "Usuario eliminado exitosamente.")
    }
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    user = Accounts.get_user!(String.to_integer(id))
    changeset = Accounts.change_user_registration(user, %{})

    {:noreply, assign(socket,
      changeset: changeset,
      editing_user: user
    )}
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    changeset = Accounts.change_user_registration(%Yachanakuy.Accounts.User{}, %{})

    {:noreply, assign(socket,
      changeset: changeset,
      editing_user: nil
    )}
  end

  @impl true
  def handle_event("reset_password", %{"id" => id}, socket) do
    user = Accounts.get_user!(String.to_integer(id))
    
    # Generate a random password
    new_password = :crypto.strong_rand_bytes(12) 
                   |> Base.url_encode64() 
                   |> binary_part(0, 12)
    
    # Update the user's password
    case Accounts.update_user_password(user, %{password: new_password, password_confirmation: new_password}) do
      {:ok, _} ->
        # TODO: In a real implementation, you would send an email to the user with the new password
        # For now, we'll just show a success message
        {:noreply, assign(socket, success_message: "Contraseña restablecida exitosamente para #{user.email}. Nueva contraseña temporal: #{new_password}")}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info({:save_user, {_component_pid, action, user_params}}, socket) do
    result = if socket.assigns.editing_user do
      # For editing, we need to handle password separately
      password_params = Map.take(user_params, ["password", "password_confirmation"])
      user_params_without_password = Map.drop(user_params, ["password", "password_confirmation"])
      
      case Accounts.update_user_registration(socket.assigns.editing_user, user_params_without_password) do
        {:ok, user} ->
          if password_params["password"] && password_params["password"] != "" do
            Accounts.update_user_password(user, password_params)
          else
            {:ok, user}
          end
        error -> error
      end
    else
      # For new users, we create with password
      Accounts.register_user(user_params)
    end

    case result do
      {:ok, _user} ->
        users = Accounts.list_users()
        changeset = Accounts.change_user_registration(%Yachanakuy.Accounts.User{}, %{})

        socket = assign(socket,
          users: users,
          changeset: changeset,
          editing_user: nil,
          success_message: if(socket.assigns.editing_user, do: "Usuario actualizado", else: "Usuario creado") <> " exitosamente"
        )

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end