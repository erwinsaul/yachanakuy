# Yachanakuy - Sistema de Gestión de Congresos

Sistema web para gestionar un único congreso académico, desde la inscripción de participantes hasta la emisión de certificados de participación. El sistema utiliza códigos QR para registrar entregas de credenciales, materiales, refrigerios y asistencia a conferencias durante el día del evento.

## Características

- **Inscripción en línea**: Los participantes pueden registrarse en línea, subir su foto y comprobante de pago
- **Aprobación de inscripciones**: Los administradores revisan y aprueban inscripciones
- **Credenciales digitales**: Genera automáticamente credenciales digitales con un código QR único
- **Registro de entregas**: El personal escanea códigos QR para registrar entregas y asistencias
- **Informes**: El personal puede ver reportes de su trabajo
- **Certificados automáticos**: Genera certificados automáticamente para los asistentes

## Arquitectura del Sistema

### Usuarios y Permisos

- **Participantes**: Se inscriben al congreso, descargan su credencial digital, solicitan su certificado
- **Administradores**: Configuran el congreso, aprueban inscripciones, ven todos los reportes
- **Encargados de Comisión**: Supervisan áreas específicas, ven el trabajo de su equipo
- **Operadores**: Personal que trabaja el día del evento, escanean códigos QR

### Base de Datos

- `settings`: Configuración singleton del congreso único
- `users`: Personal que tiene acceso al sistema
- `attendee_categories`: Tipos de participantes (Estudiante, Profesional, Ponente)
- `speakers`: Expositores o ponentes del congreso
- `rooms`: Salas o auditorios donde se realizan las conferencias
- `sessions`: Conferencias, talleres o actividades programadas
- `attendees`: Participantes inscritos en el congreso
- `commissions`: Áreas de trabajo del congreso (Acreditación, Material, Refrigerio, Asistencia)
- `meals`: Tipos de refrigerios disponibles
- `meal_deliveries`: Registro de quién recibió cada refrigerio
- `session_attendances`: Registro de asistencia a conferencias
- `certificates`: Certificados generados para participantes
- `email_logs`: Registro de todos los emails enviados
- `audit_logs`: Registro de acciones importantes en el sistema

## Instalación

1. Clonar el repositorio
2. Instalar dependencias:
   ```bash
   mix deps.get
   ```
3. Configurar la base de datos:
   ```bash
   mix ecto.setup
   ```
4. Iniciar el servidor:
   ```bash
   mix phx.server
   ```

## Configuración Inicial

El sistema incluye datos iniciales que se configuran con:

```bash
mix run priv/repo/seeds.exs
```

Esto crea:
- Configuración del congreso
- Categorías de participantes (Estudiante, Profesional, Ponente)
- Comisiones estándar (Acreditación, Material, Refrigerio, Asistencia)
- Un usuario administrador

## Tecnologías Utilizadas

- **Elixir**: Lenguaje de programación funcional
- **Phoenix Framework**: Framework web rápido y escalable
- **Phoenix LiveView**: Interfaz de usuario dinámica sin JavaScript
- **Ecto**: Capa de datos con soporte para bases de datos SQL
- **Tailwind CSS**: Framework de CSS utilitario
- **SQLite**: Base de datos ligera

## Estructura del Proyecto

```
lib/
├── yachanakuy/           # Contextos de la aplicación
│   ├── accounts/         # Autenticación y usuarios
│   ├── events/           # Configuración del congreso
│   ├── program/          # Sesiones, expositores y salas
│   ├── registration/     # Inscripciones de participantes
│   ├── commissions/      # Áreas de trabajo
│   ├── deliveries/       # Entregas y asistencias
│   ├── certificates/     # Certificados
│   └── logs/             # Registros y auditoría
└── yachanakuy_web/       # Componentes web y vistas
    ├── components/       # Componentes reutilizables
    ├── live/             # LiveViews organizados por rol
    │   ├── admin/        # Área administrativa
    │   ├── staff/        # Área de personal
    │   ├── supervisor/   # Área de supervisión
    │   └── public/       # Área pública
    └── controllers/      # Controladores
```

## Despliegue

El sistema está preparado para despliegue con releases de Elixir.

## Licencia

[MIT License]
