defmodule FarmbotSlackbot.Application do
  use Application
  require Logger

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec
    install_nerves_bootstrap()
    # install_fwup()

    # Define workers and child supervisors to be supervised
    children = [
      # worker(Task, [__MODULE__, :install_nerves_bootstrap, []]),
      # Start the endpoint when the application starts
      supervisor(FarmbotSlackbotWeb.Endpoint, []),
      # worker(FarmbotSlackbot.SlackClient, []),
      # Start your own worker by calling: FarmbotSlackbot.Worker.start_link(arg1, arg2, arg3)
      # worker(FarmbotSlackbot.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FarmbotSlackbot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    FarmbotSlackbotWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def install_nerves_bootstrap do
    unless File.exists?("bootstrap_installed") do
      Logger.debug "installing nerves"
      Mix.Tasks.Archive.Install.run ["hex", "nerves_bootstrap", "--force"]
      File.write!("bootstrap_installed", "OK")
    end
    :ok
  end

  # @fwup_dl_url "https://github.com/fhunleth/fwup/releases/download/v0.18.1/fwup_0.18.1_amd64.deb" |> to_charlist()
  #
  # def install_fwup do
  #   unless File.exists?("fwup_installed!") do
  #     Logger.debug "installing fwup"
  #     {:ok, {{_, 200, _}, _, bin}} = :httpc.request(:get, {@fwup_dl_url, []}, [{:autoredirect, true}, {:body_format, :binary}], [{:autoredirect, true}, {:body_format, :binary}])
  #     File.write!("/tmp/fwup_0.18.1_amd64.deb", bin)
  #     require IEx; IEx.pry
  #   end
  # end
end
