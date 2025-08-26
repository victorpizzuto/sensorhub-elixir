defmodule SensorhubElixir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SensorhubElixir.Repo,
      {DNSCluster, query: Application.get_env(:sensorhub_elixir, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SensorhubElixir.PubSub}
      # Start a worker by calling: SensorhubElixir.Worker.start_link(arg)
      # {SensorhubElixir.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: SensorhubElixir.Supervisor)
  end
end
