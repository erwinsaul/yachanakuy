defmodule Yachanakuy.Deliveries do
  @moduledoc """
  The Deliveries context.
  """
  import Ecto.Query, warn: false
  alias Yachanakuy.Repo

  alias Yachanakuy.Deliveries.Meal

  def list_meals do
    Repo.all(Meal)
  end

  def get_meal!(id) do
    Repo.get!(Meal, id)
  end

  def create_meal(attrs \\ %{}) do
    %Meal{}
    |> Meal.changeset(attrs)
    |> Repo.insert()
  end

  def update_meal(%Meal{} = meal, attrs) do
    meal
    |> Meal.changeset(attrs)
    |> Repo.update()
  end

  def delete_meal(%Meal{} = meal) do
    Repo.delete(meal)
  end

  def change_meal(%Meal{} = meal, attrs \\ %{}) do
    Meal.changeset(meal, attrs)
  end

  alias Yachanakuy.Deliveries.MealDelivery

  def list_meal_deliveries do
    Repo.all(MealDelivery)
  end

  def get_meal_delivery!(id) do
    Repo.get!(MealDelivery, id)
  end

  def create_meal_delivery(attrs \\ %{}) do
    %MealDelivery{}
    |> MealDelivery.changeset(attrs)
    |> Repo.insert()
  end

  def update_meal_delivery(%MealDelivery{} = meal_delivery, attrs) do
    meal_delivery
    |> MealDelivery.changeset(attrs)
    |> Repo.update()
  end

  def delete_meal_delivery(%MealDelivery{} = meal_delivery) do
    Repo.delete(meal_delivery)
  end

  def change_meal_delivery(%MealDelivery{} = meal_delivery, attrs \\ %{}) do
    MealDelivery.changeset(meal_delivery, attrs)
  end

  def get_delivery_by_attendee_and_meal(attendee_id, meal_id) do
    Repo.get_by(MealDelivery, attendee_id: attendee_id, meal_id: meal_id)
  end

  alias Yachanakuy.Deliveries.SessionAttendance

  def list_session_attendances do
    Repo.all(SessionAttendance)
  end

  def get_session_attendance!(id) do
    Repo.get!(SessionAttendance, id)
  end

  def create_session_attendance(attrs \\ %{}) do
    %SessionAttendance{}
    |> SessionAttendance.changeset(attrs)
    |> Repo.insert()
  end

  def update_session_attendance(%SessionAttendance{} = session_attendance, attrs) do
    session_attendance
    |> SessionAttendance.changeset(attrs)
    |> Repo.update()
  end

  def delete_session_attendance(%SessionAttendance{} = session_attendance) do
    Repo.delete(session_attendance)
  end

  def change_session_attendance(%SessionAttendance{} = session_attendance, attrs \\ %{}) do
    SessionAttendance.changeset(session_attendance, attrs)
  end

  def get_attendance_by_attendee_and_session(attendee_id, session_id) do
    Repo.get_by(SessionAttendance, attendee_id: attendee_id, session_id: session_id)
  end

  def count_deliveries_by_user(user_id) do
    import Ecto.Query

    meal_delivery_query = from md in MealDelivery,
      where: md.entregado_por == ^user_id

    session_attendance_query = from sa in SessionAttendance,
      where: sa.escaneado_por == ^user_id

    meal_deliveries_count = Repo.aggregate(meal_delivery_query, :count, :id)
    session_attendances_count = Repo.aggregate(session_attendance_query, :count, :id)

    meal_deliveries_count + session_attendances_count
  end

  def count_deliveries_by_commission(commission_id) do
    import Ecto.Query

    # Get the commission to determine its type
    case get_commission_type(commission_id) do
      "ACRED" ->  # Acreditación - credential delivery
        query = from a in Yachanakuy.Registration.Attendee,
          where: a.quien_entrego_credencial in subquery(get_users_in_commission_query(commission_id)),
          select: count(a.id)
        Repo.one(query) || 0

      "MAT" ->  # Material delivery
        query = from a in Yachanakuy.Registration.Attendee,
          where: a.quien_entrego_material in subquery(get_users_in_commission_query(commission_id)),
          select: count(a.id)
        Repo.one(query) || 0

      "REFRI" ->  # Meal delivery
        query = from md in MealDelivery,
          where: md.entregado_por in subquery(get_users_in_commission_query(commission_id)),
          select: count(md.id)
        Repo.one(query) || 0

      _ -> 0  # Default case
    end
  end

  def count_attendances_by_commission(commission_id) do
    import Ecto.Query

    # Asistencia - session attendance
    case get_commission_type(commission_id) do
      "ASIST" ->  # Asistencia
        query = from sa in SessionAttendance,
          where: sa.escaneado_por in subquery(get_users_in_commission_query(commission_id)),
          select: count(sa.id)
        Repo.one(query) || 0

      _ -> 0  # For other types, no session attendances are tracked
    end
  end

  # Funciones específicas para la entrega de credenciales
  def deliver_credential(%Yachanakuy.Registration.Attendee{} = attendee, %Yachanakuy.Accounts.User{} = user) do
    # Validar que el estado sea aprobado
    if attendee.estado != "aprobado" do
      {:error, "No se puede entregar credencial a un participante no aprobado"}
    else
      # Actualizar el estado de la credencial en el attendee
      attendee_changeset = Yachanakuy.Registration.Attendee.changeset(attendee, %{
        credencial_entregada: true,
        fecha_entrega_credencial: DateTime.utc_now(),
        quien_entrego_credencial: user.id
      })

      Repo.transaction(fn ->
        # Actualizar el attendee
        case Repo.update(attendee_changeset) do
          {:ok, updated_attendee} ->
            # Registrar en logs de auditoría
            audit_log = %{
              user_id: user.id,
              accion: "entregar_credencial",
              tipo_recurso: "Participante",
              id_recurso: updated_attendee.id,
              cambios: Jason.encode!(%{
                anterior_estado_credencial: attendee.credencial_entregada,
                nuevo_estado_credencial: true,
                entregado_por: user.id
              })
            }

            Yachanakuy.Logs.create_audit_log(audit_log)

            updated_attendee
          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    end
  end

  # Funciones específicas para la entrega de materiales
  def deliver_material(%Yachanakuy.Registration.Attendee{} = attendee, %Yachanakuy.Accounts.User{} = user) do
    # Validar que el estado sea aprobado
    if attendee.estado != "aprobado" do
      {:error, "No se puede entregar material a un participante no aprobado"}
    else
      # Actualizar el estado del material en el attendee
      attendee_changeset = Yachanakuy.Registration.Attendee.changeset(attendee, %{
        material_entregado: true,
        fecha_entrega_material: DateTime.utc_now(),
        quien_entrego_material: user.id
      })

      Repo.transaction(fn ->
        # Actualizar el attendee
        case Repo.update(attendee_changeset) do
          {:ok, updated_attendee} ->
            # Registrar en logs de auditoría
            audit_log = %{
              user_id: user.id,
              accion: "entregar_material",
              tipo_recurso: "Participante",
              id_recurso: updated_attendee.id,
              cambios: Jason.encode!(%{
                anterior_estado_material: attendee.material_entregado,
                nuevo_estado_material: true,
                entregado_por: user.id
              })
            }

            Yachanakuy.Logs.create_audit_log(audit_log)

            updated_attendee
          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    end
  end

  # Función para registrar la entrega de un refrigerio
  def register_meal_delivery(attendee_id, meal_id, %Yachanakuy.Accounts.User{} = user) do
    # Validar que el participante no haya recibido este refrigerio antes
    existing_delivery = get_delivery_by_attendee_and_meal(attendee_id, meal_id)
    if existing_delivery do
      {:error, "El participante ya recibió este refrigerio"}
    else
      # Validar que el participante exista y esté aprobado
      attendee = Yachanakuy.Registration.get_attendee!(attendee_id)
      if attendee.estado != "aprobado" do
        {:error, "No se puede entregar refrigerio a un participante no aprobado"}
      else
        attrs = %{
          attendee_id: attendee_id,
          meal_id: meal_id,
          entregado_por: user.id,
          fecha_entrega: DateTime.utc_now()
        }

        Repo.transaction(fn ->
          # Crear la entrega
          case create_meal_delivery(attrs) do
            {:ok, meal_delivery} ->
              # Registrar en logs de auditoría
              audit_log = %{
                user_id: user.id,
                accion: "entregar_refrigerio",
                tipo_recurso: "Refrigerio",
                id_recurso: meal_delivery.id,
                cambios: Jason.encode!(%{
                  attendee_id: attendee_id,
                  meal_id: meal_id,
                  entregado_por: user.id
                })
              }

              Yachanakuy.Logs.create_audit_log(audit_log)

              meal_delivery
            {:error, changeset} ->
              Repo.rollback(changeset)
          end
        end)
      end
    end
  end

  # Función para registrar asistencia a una sesión
  def register_session_attendance(attendee_id, session_id, %Yachanakuy.Accounts.User{} = user) do
    # Validar que el participante no haya asistido a esta sesión antes
    existing_attendance = get_attendance_by_attendee_and_session(attendee_id, session_id)
    if existing_attendance do
      {:error, "El participante ya asistió a esta sesión"}
    else
      # Validar que el participante exista y esté aprobado
      attendee = Yachanakuy.Registration.get_attendee!(attendee_id)
      if attendee.estado != "aprobado" do
        {:error, "No se puede registrar asistencia de un participante no aprobado"}
      else
        attrs = %{
          attendee_id: attendee_id,
          session_id: session_id,
          escaneado_por: user.id,
          fecha_escaneo: DateTime.utc_now()
        }

        Repo.transaction(fn ->
          # Crear el registro de asistencia
          case create_session_attendance(attrs) do
            {:ok, session_attendance} ->
              # Actualizar el contador de sesiones asistidas en el attendee
              updated_sesiones_asistidas = (attendee.sesiones_asistidas || 0) + 1
              attendee_changeset = Yachanakuy.Registration.Attendee.changeset(attendee, %{
                sesiones_asistidas: updated_sesiones_asistidas
              })
              
              case Repo.update(attendee_changeset) do
                {:ok, updated_attendee} ->
                  # Registrar en logs de auditoría
                  audit_log = %{
                    user_id: user.id,
                    accion: "registrar_asistencia_sesion",
                    tipo_recurso: "Sesión",
                    id_recurso: session_attendance.id,
                    cambios: Jason.encode!(%{
                      attendee_id: attendee_id,
                      session_id: session_id,
                      escaneado_por: user.id,
                      sesiones_asistidas_anterior: attendee.sesiones_asistidas,
                      sesiones_asistidas_nuevo: updated_sesiones_asistidas
                    })
                  }

                  Yachanakuy.Logs.create_audit_log(audit_log)

                  # Devolver tanto el registro de asistencia como el attendee actualizado
                  {:ok, %{session_attendance: session_attendance, attendee: updated_attendee}}
                {:error, changeset} ->
                  Repo.rollback(changeset)
              end
            {:error, changeset} ->
              Repo.rollback(changeset)
          end
        end)
      end
    end
  end
end

  defp get_commission_type(commission_id) do
    import Ecto.Query

    query = from c in Yachanakuy.Commissions.Commission,
      where: c.id == ^commission_id,
      select: c.codigo

  defp get_users_in_commission_query(commission_id) do
    import Ecto.Query

    from co in Yachanakuy.Commissions.CommissionOperator,
      where: co.commission_id == ^commission_id,
      select: co.user_id
end
