defmodule Yachanakuy.Repo.Migrations.AddMissingIndicesForPerformance do
  use Ecto.Migration

  @moduledoc """
  Migration para agregar índices faltantes que mejoran el rendimiento de las consultas más comunes.

  ## Índices agregados

  ### Para la tabla `attendees`:
  - Índice en `estado` para filtrar por estado de inscripción
  - Índice en `fecha_revision` para ordenar por fecha de revisión
  - Índice en `fecha_entrega_credencial` para ordenar por fecha de entrega de credencial
  - Índice en `fecha_entrega_material` para ordenar por fecha de entrega de material
  - Índice en `sesiones_asistidas` para ordenar por número de sesiones asistidas
  - Índice compuesto en `estado, categoria_id` para filtrar por estado y categoría

  ### Para la tabla `meal_deliveries`:
  - Índice en `fecha_entrega` para ordenar por fecha de entrega
  - Índice compuesto en `entregado_por, fecha_entrega` para filtrar por usuario y ordenar por fecha

  ### Para la tabla `session_attendances`:
  - Índice en `fecha_escaneo` para ordenar por fecha de escaneo
  - Índice compuesto en `escaneado_por, fecha_escaneo` para filtrar por usuario y ordenar por fecha

  ### Para la tabla `audit_logs`:
  - Índice compuesto en `user_id, accion` para filtrar por usuario y acción
  - Índice compuesto en `tipo_recurso, id_recurso` para filtrar por tipo y ID de recurso
  - Índice compuesto en `fecha_accion, accion` para ordenar por fecha y filtrar por acción

  ### Para la tabla `email_logs`:
  - Índice en `fecha_envio` para ordenar por fecha de envío
  - Índice compuesto en `tipo_email, estado` para filtrar por tipo y estado
  - Índice compuesto en `fecha_envio, tipo_email` para ordenar por fecha y filtrar por tipo

  ### Para la tabla `certificates`:
  - Índice en `fecha_generacion` para ordenar por fecha de generación
  - Índice en `codigo_verificacion` para búsquedas por código de verificación
  - Índice compuesto en `attendee_id, fecha_generacion` para filtrar por participante y ordenar por fecha

  ### Para la tabla `commissions`:
  - Índice en `codigo` para búsquedas por código de comisión
  - Índice en `encargado_id` para búsquedas por encargado

  ### Para la tabla `commission_operators`:
  - (Omitidos - ya existen en la migración create_commission_operators)

  ### Para la tabla `users`:
  - Índice en `rol` para filtrar por rol de usuario
  - Índice en `activo` para filtrar por estado de activación
  - Índice compuesto en `rol, activo` para filtrar por rol y estado

  ### Para la tabla `sessions`:
  - Índice en `hora_inicio` para ordenar por hora de inicio
  - Índice en `hora_fin` para ordenar por hora de fin
  - Índice compuesto en `fecha, hora_inicio` para ordenar por fecha y hora
  - (Nota: índice en `fecha` ya existe en create_sessions)

  ### Para la tabla `rooms`:
  - Índice en `capacidad` para filtrar por capacidad

  ### Para la tabla `speakers`:
  - Índice en `institucion` para filtrar por institución

  ### Para la tabla `attendee_categories`:
  - Índice en `codigo` para búsquedas por código de categoría
  - Índice en `precio` para filtrar por precio
  """

  def change do
    # Índices para la tabla `attendees`
    create index(:attendees, [:estado])
    create index(:attendees, [:fecha_revision])
    create index(:attendees, [:fecha_entrega_credencial])
    create index(:attendees, [:fecha_entrega_material])
    create index(:attendees, [:sesiones_asistidas])
    create index(:attendees, [:estado, :category_id])

    # Índices para la tabla `meal_deliveries`
    create index(:meal_deliveries, [:fecha_entrega])
    create index(:meal_deliveries, [:entregado_por, :fecha_entrega])

    # Índices para la tabla `session_attendances`
    create index(:session_attendances, [:fecha_escaneo])
    create index(:session_attendances, [:escaneado_por, :fecha_escaneo])

    # Índices para la tabla `audit_logs`
    create index(:audit_logs, [:user_id, :accion])
    create index(:audit_logs, [:tipo_recurso, :id_recurso])
    create index(:audit_logs, [:fecha_accion, :accion])

    # Índices para la tabla `email_logs`
    create index(:email_logs, [:tipo_email, :estado])
    create index(:email_logs, [:fecha_envio, :tipo_email])

    # Índices para la tabla `certificates`
    create index(:certificates, [:fecha_generacion])
    create index(:certificates, [:attendee_id, :fecha_generacion])

    # Índices para la tabla `commissions`

    # Índices para la tabla `commission_operators`
    # Nota: el índice [:user_id] ya existe en la migración create_commission_operators
    # Nota: el índice [:user_id, :commission_id] ya existe como unique_index en create_commission_operators

    # Índices para la tabla `users`
    create index(:users, [:rol])
    create index(:users, [:activo])
    create index(:users, [:rol, :activo])

    # Índices para la tabla `sessions`
    # Nota: el índice [:fecha] ya existe en la migración create_sessions
    create index(:sessions, [:hora_inicio])
    create index(:sessions, [:hora_fin])
    create index(:sessions, [:fecha, :hora_inicio])

    # Índices para la tabla `rooms`
    create index(:rooms, [:capacidad])

    # Índices para la tabla `speakers`
    create index(:speakers, [:institucion])

    # Índices para la tabla `attendee_categories`
    create index(:attendee_categories, [:precio])
  end
end