defmodule FarmbotSlackbotWeb.RootController do
  use FarmbotSlackbotWeb, :controller

  def index(conn, _) do
    send_resp(conn, 200, "Hello")
  end
end
