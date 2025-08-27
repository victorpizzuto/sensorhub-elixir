# SensorhubElixir.Umbrella
## Creating project struct

```bash
mix phx.new sensorhub_elixir --umbrella --binary-id --install
cd apps && mix new sensorhub_elixir_timeseries --module SensorhubElixirTimeseries
cd apps && mix new sensorhub_elixir_jobs --module SensorhubElixirJobs
cd apps && mix new sensorhub_elixir_mqtt --module SensorhubElixirMqtt
cd apps && mix new sensorhub_elixir_cluster --module SensorhubElixirCluster
```
