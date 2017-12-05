defmodule FarmbotSlackbot.FirmwareBuilder do
  require Logger

  @work_dir Application.get_env(:farmbot_slackbot, :work_dir)
  @nerves_dir Path.join(System.user_home, ".nerves")

  def full_build(commit \\ "staging") do
    Logger.debug "Doing full build"
    if File.exists?("#{@work_dir}/current_build") do
      raise "Build already in progress"
    end
    clone(commit)
    get_deps()
    build_firmware()
    upload_firmware()
  rescue
    err ->
      Logger.error "build failed: #{inspect Exception.message(err)}"
      File.rm "#{@work_dir}/current_build"
  end

  def clone(commit) do
    Logger.debug "Cloning"
    if File.exists?("#{@work_dir}/#{commit}") do
      File.rm_rf!("#{@work_dir}/#{commit}")
    end
    File.mkdir_p!("#{@work_dir}/#{commit}")
    File.cd!("#{@work_dir}/#{commit}")
    System.cmd("git", ["clone", "https://github.com/farmbot/farmbot_os", "#{@work_dir}/#{commit}"], opts()) |> check_res()
    Logger.debug "Checking out"
    System.cmd("git", ["checkout", "#{commit}"], opts()) |> check_res()
    File.write!("#{@work_dir}/current_build", commit)
  end

  def get_deps do
    Logger.debug "mix deps.get"
    File.cd!("#{@work_dir}/#{current_build()}")
    System.cmd("mix", ["deps.get"], opts()) |> check_res()
  end

  def build_firmware do
    Logger.debug "mix firmware"
    File.cd!("#{@work_dir}/#{current_build()}")
    System.cmd("mix", ["firmware"], opts()) |> check_res()
  end

  def upload_firmware do
    Logger.debug "uploading to slack"
    File.cd!("#{@work_dir}/#{current_build()}")
    System.cmd("mix", ["firmware.slack"], opts()) |> check_res()
    File.rm "#{@work_dir}/current_build"
  end

  def env do
    [{"MIX_ENV", "dev"}, {"MIX_TARGET", "rpi3"}, {"SLACK_TOKEN", Application.get_env(:ex_slack, :token)}]
  end

  defp opts do
    [stderr_to_stdout: true, env: env(), into: IO.stream(:stdio, :line)]
  end

  defp check_res({_, 0}), do: :ok
  defp check_res({_, err}), do: raise "Command failed: #{err}"

  defp current_build do
    File.read!("#{@work_dir}/current_build")
  end
end
