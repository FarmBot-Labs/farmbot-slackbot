defmodule FarmbotSlackbot.SlackClient do
  require Logger
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], [])
  end

  def stop(client, reason \\ :shutdown) do
    GenServer.stop(client, reason)
  end

  def init([]) do
    {:ok, pid} = Slack.RtmApi.start_link()
    Logger.info "Connected to slack"
    {:ok, %{rtm: pid}}
  end

  def handle_info({:slack_rtm, type, data}, state) do
    Logger.info "Got slack #{type} message: #{inspect data}"
    {:noreply, state}
  end

  def terminate(reason, state) do
    if state.rtm do
      Logger.debug "Disconnecting from Slack."
      Slack.RtmApi.stop(state.rtm, reason)
    end
  end
end
