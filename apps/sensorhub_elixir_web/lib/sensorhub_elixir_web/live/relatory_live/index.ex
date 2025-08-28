defmodule SensorhubElixirWeb.RelatoryLive.Index do
  use SensorhubElixirWeb, :live_view

  alias SensorhubElixirWeb.Dashboard

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Telemetry Dashboard
      <:subtitle>Real-time Telemetry Data</:subtitle>
    </.header>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      <div class="bg-white p-6 rounded-lg shadow">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Speed Data</h3>
        <div
          id="velocity-chart"
          phx-hook="TelemetryChart"
          data-chart-data={Jason.encode!(@velocity_data)}
          style="height: 400px;"
        >
        </div>
      </div>

      <div class="bg-white p-6 rounded-lg shadow">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Temperature Data</h3>
        <div
          id="temperature-chart"
          phx-hook="TelemetryChart"
          data-chart-data={Jason.encode!(@temperature_data)}
          style="height: 400px;"
        >
        </div>
      </div>
    </div>

    <div class="mt-8 bg-white p-6 rounded-lg shadow">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Available Reports</h3>

      <%= if @reports != [] do %>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  File
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Size
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Date
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for report <- @reports do %>
                <tr class="hover:bg-gray-50">
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {report.filename}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {report.size}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {report.modified}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium">
                    <%= if report.download_url do %>
                      <a
                        href={report.download_url}
                        target="_blank"
                        class="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                      >
                        <svg
                          class="-ml-0.5 mr-2 h-4 w-4"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                          />
                        </svg>
                        Download
                      </a>
                    <% else %>
                      <span class="text-gray-400">Unavailable</span>
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% else %>
        <div class="text-center py-8">
          <svg
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No reports found</h3>
          <p class="mt-1 text-sm text-gray-500">
            Reports are generated automatically every 10 minutes.
          </p>
        </div>
      <% end %>

      <div class="mt-4 flex justify-between items-center">
        <button
          phx-click="refresh_reports"
          class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
        >
          <svg class="-ml-0.5 mr-2 h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
          Refresh List
        </button>

        <span class="text-sm text-gray-500">
          Total: {length(@reports)} file(s)
        </span>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(SensorhubElixir.PubSub, "telemetry:data")
    end

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> get_reports()
     |> load_dashboard_data()}
  end

  @impl true
  def handle_info(:update_data, socket) do
    {:noreply, socket}
  end

  def handle_info({:new_telemetry, data}, socket) do
    velocity_data = Dashboard.parse_new_message(data, socket.assigns.velocity_data)
    temperature_data = Dashboard.parse_new_message(data, socket.assigns.temperature_data)

    if velocity_data != socket.assigns.velocity_data do
      send_update_to_chart("velocity-chart-update", velocity_data)
    end

    if temperature_data != socket.assigns.temperature_data do
      send_update_to_chart("temperature-chart-update", temperature_data)
    end

    {:noreply,
     socket
     |> assign(:velocity_data, velocity_data)
     |> assign(:temperature_data, temperature_data)}
  end

  def handle_info({:push_chart_update, event_name, data}, socket) do
    {:noreply, push_event(socket, event_name, data)}
  end

  defp send_update_to_chart(event_name, data) do
    Process.send_after(self(), {:push_chart_update, event_name, data}, 100)
  end

  defp load_dashboard_data(socket) do
    velocity_data = Dashboard.get_velocity_data()
    temperature_data = Dashboard.get_temperature_data()

    socket
    |> assign(:velocity_data, velocity_data)
    |> assign(:temperature_data, temperature_data)
  end

  @impl true
  def handle_event("refresh_reports", _params, socket) do
    {:noreply, get_reports(socket)}
  end

  defp get_reports(socket) do
    reports =
      try do
        SensorhubElixirJobs.Relatory.list_reports()
      rescue
        _ -> []
      end

    socket
    |> assign(:reports, reports)
  end
end
