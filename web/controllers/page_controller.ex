defmodule DoubleKingPedro.PageController do
  use DoubleKingPedro.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
