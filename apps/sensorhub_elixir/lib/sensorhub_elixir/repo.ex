defmodule SensorhubElixir.Repo do
  use Ecto.Repo,
    otp_app: :sensorhub_elixir,
    adapter: Ecto.Adapters.Postgres
end
