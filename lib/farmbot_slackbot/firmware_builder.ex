defmodule FarmbotSlackbot.FirmwareBuilder do
  require Logger

  @work_dir Application.get_env(:farmbot_slackbot, :work_dir)

  def full_build(cb, channel, commit \\ "staging") do
    Logger.debug "Doing full build"
    if File.exists?("#{@work_dir}/current_build") do
      raise "Build already in progress"
    end
    clone(cb, commit)
    get_deps(cb)
    build_firmware(cb)
    upload_firmware(cb, channel)
  rescue
    err ->
      Logger.error "build failed: #{inspect Exception.message(err)}"
      File.rm "#{@work_dir}/current_build"
      send cb, :error

    send cb, :done
  end

  def reset do
    File.rm "#{@work_dir}/current_build"
  end

  def clone(cb, commit) do
    Logger.debug "Cloning"
    send cb, {:clone, :begin}
    if File.exists?("#{@work_dir}/#{commit}") do
      File.rm_rf!("#{@work_dir}/#{commit}")
    end
    File.mkdir_p!("#{@work_dir}/#{commit}")
    File.cd!("#{@work_dir}/#{commit}")
    System.cmd("git", ["clone", "https://github.com/farmbot/farmbot_os", "#{@work_dir}/#{commit}"], opts()) |> check_res()
    Logger.debug "Checking out"
    System.cmd("git", ["checkout", "#{commit}"], opts()) |> check_res()
    File.write!("#{@work_dir}/current_build", commit)
    send cb, {:clone, :finish}
  end

  def get_deps(cb) do
    send(cb, {:deps, :begin})
    Logger.debug "mix deps.get"
    File.cd!("#{@work_dir}/#{current_build()}")
    System.cmd("mix", ["deps.get"], opts()) |> check_res()
    send(cb, {:deps, :finish})
  end

  def build_firmware(cb) do
    send(cb, {:firmware, :begin})
    Logger.debug "mix firmware"
    File.cd!("#{@work_dir}/#{current_build()}")
    System.cmd("mix", ["firmware"], opts()) |> check_res()
    send(cb, {:firmware, :finish})
  end

  def upload_firmware(cb, channel) do
    send(cb, {:upload, :begin})
    Logger.debug "uploading to slack"
    File.cd!("#{@work_dir}/#{current_build()}")
    System.cmd("mix", ["firmware.slack", "--channels", channel], opts()) |> check_res()
    File.rm "#{@work_dir}/current_build"
    send(cb, {:upload, :finish})
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
