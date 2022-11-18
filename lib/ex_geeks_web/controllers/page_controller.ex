defmodule ExGeeksWeb.PageController do
  use ExGeeksWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
