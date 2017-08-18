defmodule DoubleKingPedro.Router do
  use DoubleKingPedro.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
     plug :put_user_token
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DoubleKingPedro do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", DoubleKingPedro do
  #   pipe_through :api
  # end

  defp put_user_token(conn, _) do
    token = Phoenix.Token.sign(conn, "user socket", Ecto.UUID.generate)
    assign(conn, :user_token, token)
  end
end
