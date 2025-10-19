# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Yachanakuy.Repo.insert!(%Yachanakuy.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Yachanakuy.Repo
alias Yachanakuy.Events.Settings
alias Yachanakuy.Events.AttendeeCategory
alias Yachanakuy.Commissions.Commission
alias Yachanakuy.Accounts.User

# Create settings if it doesn't already exist
if Repo.aggregate(Settings, :count, :id) == 0 do
  %Settings{}
  |> Settings.changeset(%{
    nombre: "Congreso Internacional de Tecnología 2025",
    descripcion: "Un congreso académico para compartir conocimientos y experiencias sobre los temas más relevantes del sector tecnológico.",
    fecha_inicio: ~D[2025-04-15],
    fecha_fin: ~D[2025-04-17],
    ubicacion: "La Paz, Bolivia",
    direccion_evento: "Av. 16 de Julio #123, La Paz, Bolivia",
    logo: "/images/congreso-logo.png",
    estado: "borrador",
    inscripciones_abiertas: false,
    info_turismo: """
    La ciudad de La Paz es la sede de gobierno de Bolivia y ofrece numerosos atractivos turísticos:
    - Valle de la Luna: formaciones geológicas únicas
    - Teleférico: sistema de transporte urbano más alto del mundo
    - Plaza Murillo: centro histórico con arquitectura colonial
    - Iglesia de San Francisco: ejemplo de arte barroco colonial
    """
  })
  |> Repo.insert!()

  IO.puts("Settings created successfully")
else
  IO.puts("Settings already exists, skipping...")
end

# Create attendee categories if they don't exist
categories = [
  %{nombre: "Estudiante", codigo: "EST", precio: Decimal.new("50.00"), color: "#3b82f6"},  # Blue
  %{nombre: "Profesional", codigo: "PROF", precio: Decimal.new("100.00"), color: "#ef4444"}, # Red
  %{nombre: "Ponente", codigo: "PON", precio: Decimal.new("0.00"), color: "#8b5cf6"}  # Purple
]

Enum.each(categories, fn category_attrs ->
  if Repo.get_by(AttendeeCategory, codigo: category_attrs.codigo) == nil do
    %AttendeeCategory{}
    |> AttendeeCategory.changeset(category_attrs)
    |> Repo.insert!()
    
    IO.puts("Category #{category_attrs.nombre} created successfully")
  else
    IO.puts("Category #{category_attrs.nombre} already exists, skipping...")
  end
end)

# Create standard commissions if they don't exist
commissions = [
  %{nombre: "Acreditación", codigo: "ACRED"},
  %{nombre: "Material", codigo: "MAT"},
  %{nombre: "Refrigerio", codigo: "REFRI"},
  %{nombre: "Asistencia", codigo: "ASIST"}
]

Enum.each(commissions, fn commission_attrs ->
  if Repo.get_by(Commission, codigo: commission_attrs.codigo) == nil do
    %Commission{}
    |> Commission.changeset(commission_attrs)
    |> Repo.insert!()
    
    IO.puts("Commission #{commission_attrs.nombre} created successfully")
  else
    IO.puts("Commission #{commission_attrs.nombre} already exists, skipping...")
  end
end)

# Create users if they don't exist
users = [
  %{
    nombre_completo: "Administrador del Sistema",
    email: "admin@yachanakuy.com",
    rol: "admin",
    activo: true,
    password: "password"
  },
  %{
    nombre_completo: "Encargado de Acreditación",
    email: "encargado1@yachanakuy.com",
    rol: "encargado_comision",
    activo: true,
    password: "password"
  },
  %{
    nombre_completo: "Encargado de Material",
    email: "encargado2@yachanakuy.com",
    rol: "encargado_comision",
    activo: true,
    password: "password"
  },
  %{
    nombre_completo: "Operador de Acreditación",
    email: "operador1@yachanakuy.com",
    rol: "operador",
    activo: true,
    password: "password"
  },
  %{
    nombre_completo: "Operador de Material",
    email: "operador2@yachanakuy.com",
    rol: "operador",
    activo: true,
    password: "password"
  }
]

Enum.each(users, fn user_attrs ->
  if Repo.get_by(User, email: user_attrs.email) == nil do
    hashed_password = Bcrypt.hash_pwd_salt(user_attrs.password)

    %User{}
    |> User.email_changeset(%{
      nombre_completo: user_attrs.nombre_completo,
      email: user_attrs.email,
      rol: user_attrs.rol,
      activo: user_attrs.activo
    })
    |> Ecto.Changeset.put_change(:hashed_password, hashed_password)
    |> Repo.insert!()

    IO.puts("User #{user_attrs.nombre_completo} created successfully")
  else
    IO.puts("User #{user_attrs.email} already exists, skipping...")
  end
end)

IO.puts("\n=== RESUMEN DE SEEDING ===")
IO.puts("Settings: #{Repo.aggregate(Settings, :count, :id)}")
IO.puts("Categorías: #{Repo.aggregate(AttendeeCategory, :count, :id)}")
IO.puts("Comisiones: #{Repo.aggregate(Commission, :count, :id)}")
IO.puts("Usuarios: #{Repo.aggregate(User, :count, :id)}")
IO.puts("\n=== CREDENCIALES DE ACCESO ===")
IO.puts("🔑 Administrador:")
IO.puts("   Email: admin@yachanakuy.com")
IO.puts("   Password: password")
IO.puts("\n🔑 Encargados de Comisión:")
IO.puts("   Email: encargado1@yachanakuy.com (Acreditación)")
IO.puts("   Email: encargado2@yachanakuy.com (Material)")
IO.puts("   Password: password")
IO.puts("\n🔑 Operadores:")
IO.puts("   Email: operador1@yachanakuy.com (Acreditación)")
IO.puts("   Email: operador2@yachanakuy.com (Material)")
IO.puts("   Password: password")
IO.puts("\n✅ Seeding completed!")