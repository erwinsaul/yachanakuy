defmodule YachanakuyWeb.Router do
  use YachanakuyWeb, :router
  import YachanakuyWeb.UserAuth
  import YachanakuyWeb.AuthorizationPlug

  # ============================================
  # PIPELINES
  # ============================================
  
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {YachanakuyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Authentication pipelines (simplified - no redundancy)
  pipeline :require_auth do
    plug :require_authenticated_user
  end

  pipeline :require_admin do
    plug :require_authenticated_user
    plug :require_admin_role
  end

  pipeline :require_staff do
    plug :require_authenticated_user
    plug :require_staff_role
  end

  pipeline :require_supervisor do
    plug :require_authenticated_user
    plug :require_supervisor_role
  end

  # ============================================
  # ÁREA PÚBLICA (sin autenticación)
  # Layout: public.html.heex
  # ============================================
  
  scope "/", YachanakuyWeb do
    pipe_through :browser

    live_session :public, 
      layout: {YachanakuyWeb.Layouts, :public} do
      
      live "/", Public.SpaLive, :index
      live "/programa", Public.ProgramLive, :index
      live "/expositores", Public.SpeakersLive, :index
      live "/inscripcion", Public.RegistrationLive, :index
      live "/credencial/descargar", Public.CredentialDownloadLive, :index
      live "/credencial/:token", Public.CredentialDownloadLive, :show
      live "/certificado/solicitar", Public.CertificateRequestLive, :index
      live "/certificado/verificar", Public.CertificateVerificationLive, :index
    end
  end

  # ============================================
  # ÁREA ADMINISTRATIVA (requiere rol admin)
  # Layout: admin.html.heex
  # Seguridad: Pipeline + on_mount (doble capa)
  # ============================================
  
  scope "/admin", YachanakuyWeb do
    pipe_through [:browser, :require_admin]

    live_session :admin,
      on_mount: [
        {YachanakuyWeb.UserAuth, :mount_current_user},
        {YachanakuyWeb.UserAuth, :ensure_admin}
      ],
      layout: {YachanakuyWeb.Layouts, :admin} do
      
      # Dashboard
      live "/", Admin.DashboardLive, :index
      
      # Settings
      live "/settings", Admin.SettingsLive, :index
      
      # Program management
      live "/speakers", Admin.SpeakerLive, :index
      live "/rooms", Admin.RoomLive, :index
      live "/sessions", Admin.SessionLive, :index
      
      # Attendees management
      live "/attendees", Admin.AttendeeLive, :index
      
      # Commissions management
      live "/commissions", Admin.CommissionLive, :index
    end
    
    # Event Information management
    live "/event_info", Admin.EventInfoLive, :index
    live "/event_info/new", Admin.EventInfoLive, :new
    live "/event_info/:id", Admin.EventInfoLive, :show
    live "/event_info/:id/edit", Admin.EventInfoLive, :edit
  end

  # ============================================
  # ÁREA STAFF (requiere rol operador)
  # Layout: admin.html.heex (mismo que admin)
  # Seguridad: Pipeline + on_mount (doble capa)
  # ============================================
  
  scope "/staff", YachanakuyWeb do
    pipe_through [:browser, :require_staff]

    live_session :staff,
      on_mount: [
        {YachanakuyWeb.UserAuth, :mount_current_user},
        {YachanakuyWeb.UserAuth, :ensure_staff}
      ],
      layout: {YachanakuyWeb.Layouts, :admin} do
      
      # Dashboard
      live "/", Staff.DashboardLive, :index
      
      # Credential delivery
      live "/acreditacion", Staff.CredentialDeliveryLive, :index
      
      # Material delivery
      live "/materiales", Staff.MaterialDeliveryLive, :index
      
      # Meal delivery
      live "/refrigerios", Staff.MealDeliveryLive, :index
      
      # Session check-in
      live "/asistencia", Staff.SessionAttendanceLive, :index
      
      # My activity
      live "/mi-actividad", Staff.MyActivityLive, :index
    end
  end

  # ============================================
  # ÁREA ENCARGADO (requiere rol encargado_comision)
  # Layout: admin.html.heex
  # Seguridad: Pipeline + on_mount (doble capa)
  # ============================================
  
  scope "/encargado", YachanakuyWeb do
    pipe_through [:browser, :require_supervisor]

    live_session :supervisor,
      on_mount: [
        {YachanakuyWeb.UserAuth, :mount_current_user},
        {YachanakuyWeb.UserAuth, :ensure_supervisor}
      ],
      layout: {YachanakuyWeb.Layouts, :admin} do
      
      # Dashboard
      live "/", Supervisor.DashboardLive, :index
      
      # Commission summary
      live "/resumen-comision", Supervisor.CommissionSummaryLive, :index
      
      # Operators management
      live "/operadores", Supervisor.OperatorsLive, :index
    end
  end

  # ============================================
  # AUTENTICACIÓN - Registro
  # Redirige si ya está autenticado
  # ============================================
  
  scope "/", YachanakuyWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  # ============================================
  # CONFIGURACIÓN DE USUARIO
  # Requiere autenticación
  # ============================================
  
  scope "/", YachanakuyWeb do
    pipe_through [:browser, :require_auth]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  # ============================================
  # AUTENTICACIÓN - Login/Logout
  # ============================================
  
  scope "/", YachanakuyWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  # ============================================
  # HERRAMIENTAS DE DESARROLLO
  # ============================================
  
  if Application.compile_env(:yachanakuy, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: YachanakuyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end