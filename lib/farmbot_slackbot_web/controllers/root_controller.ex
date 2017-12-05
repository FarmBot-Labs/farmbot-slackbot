defmodule FarmbotSlackbotWeb.RootController do
  use FarmbotSlackbotWeb, :controller

  Application.get_env(:farmbot_slackbot, :work_dir)

  def index(conn, _) do
    send_resp(conn, 200, "Hello")
  end

  def test(conn, _) do
    case File.exists?("#{@work_dir}current_build") do
      true ->
        send_resp conn, 500, "Build already running: #{File.read!("#{@work_dir}current_build")}"
      false ->
        spawn FarmbotSlackbot.FirmwareBuilder, :full_build, ["staging"]
        send_resp(conn, 200, "Building")
    end
  end
end
