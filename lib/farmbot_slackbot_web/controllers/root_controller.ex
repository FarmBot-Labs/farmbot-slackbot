defmodule FarmbotSlackbotWeb.RootController do
  use FarmbotSlackbotWeb, :controller

  def index(conn, _) do
    send_resp(conn, 200, "Hello")
  end

  def test(conn, _) do
    spawn FarmbotSlackbot.FirmwareBuilder, :full_build, ["staging"]
    send_resp(conn, 200, "Building")
  end
end
