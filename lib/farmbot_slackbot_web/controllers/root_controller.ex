defmodule FarmbotSlackbotWeb.RootController do
  use FarmbotSlackbotWeb, :controller

  @work_dir Path.join(Application.app_dir(:farmbot_slackbot), "work")

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
