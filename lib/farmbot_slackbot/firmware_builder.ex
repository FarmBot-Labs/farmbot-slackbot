defmodule FarmbotSlackbot.FirmwareBuilder do

  def full_build(commit \\ "staging") do
    if File.exists?("/tmp/current_build") do
      File.rm(current_build())
    end
    clone(commit)
    get_deps()
    build_firmware()
    upload_firmware()
  end

  def clone(commit) do
    if File.exists?("/tmp/#{commit}") do
      File.rm_rf!("/tmp/#{commit}")
    end
    File.mkdir_p!("/tmp/#{commit}")
    File.cd!("/tmp/#{commit}")
    System.cmd("git", ["clone", "https://github.com/farmbot/farmbot_os", "/tmp/#{commit}"], opts()) |> check_res()
    System.cmd("git", ["checkout", "#{commit}"], opts()) |> check_res()
    File.write!("/tmp/current_build", commit)
  end

  def get_deps do
    File.cd!("/tmp/#{current_build()}")
    System.cmd("mix", ["deps.get"], opts()) |> check_res()
  end

  def build_firmware do
    File.cd!("/tmp/#{current_build()}")
    System.cmd("mix", ["firmware"], opts()) |> check_res()
  end

  def upload_firmware do
    File.cd!("/tmp/#{current_build()}")
    System.cmd("mix", ["firmware.slack"], opts()) |> check_res()
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
    File.read!("/tmp/current_build")
  end
end
