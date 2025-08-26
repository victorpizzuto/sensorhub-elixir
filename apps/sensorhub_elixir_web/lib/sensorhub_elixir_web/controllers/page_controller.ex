defmodule SensorhubElixirWeb.PageController do
  use SensorhubElixirWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
