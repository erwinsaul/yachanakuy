defmodule Yachanakuy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      YachanakuyWeb.Telemetry,
      Yachanakuy.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:yachanakuy, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:yachanakuy, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Yachanakuy.PubSub},
      # Start a worker by calling: Yachanakuy.Worker.start_link(arg)
      # {Yachanakuy.Worker, arg},
      # Start to serve requests, typically the last entry
      YachanakuyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Yachanakuy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    YachanakuyWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
