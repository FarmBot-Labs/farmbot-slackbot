defmodule FarmbotSlackbotWeb.Router do
  use FarmbotSlackbotWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FarmbotSlackbotWeb do
    get "/", RootController, :index
    get "/test", RootController, :test
  end

  scope "/api", FarmbotSlackbotWeb do
    pipe_through :api
  end
end
