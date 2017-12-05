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
    FarmbotSlackbot.FirmwareBuilder.reset()
    Process.send_after(self(), :reconnect, 45_000)
    Slack.RpcApi.Users.setPresence "auto"
    {:ok, %{rtm: pid, build: false, thread_ts: nil}}
  end

  def handle_info(:reconnect, %{build: build} = state) when is_binary(build) do
    Process.send_after(self(), :reconnect, 5_000)
    {:noreply, state}
  end

  def handle_info(:reconnect, state) do
    {:stop, :restart, state}
  end

  def handle_info({:slack_rtm, "message", %{"text" => "<@U6D01KPEE> " <> text} = message}, state) do
    state = handle_message(text, message, state)
    {:noreply, state}
  end

  def handle_info({:slack_rtm, _type, _data}, state) do
    {:noreply, state}
  end

  def handle_info({step, stage}, state) do
    if state.thread_ts do
      reply = %{channel: state.build, type: "message", text: "build step *#{step}* => *#{stage}*", thread_ts: state.thread_ts}
      Slack.RtmApi.reply(state.rtm, reply)
    end
    {:noreply, state}
  end

  def handle_info(:error, state) do
    if state.thread_ts do
      reply = %{channel: state.build, type: "message", text: "build failed", thread_ts: state.thread_ts}
      Slack.RtmApi.reply(state.rtm, reply)
    end
    {:noreply, %{state | build: false, thread_ts: nil}}
  end

  def handle_info(:done, state) do
    {:noreply, %{state | build: false, thread_ts: nil}}
  end

  def terminate(reason, state) do
    if state.rtm do
      if state.build do
        reply = %{channel: state.build, type: "message", text: "build failed!", thread_ts: state.thread_ts}
        Slack.RtmApi.reply(state.rtm, reply)
      end

      Logger.debug "Disconnecting from Slack."
      Slack.RpcApi.Users.setPresence "away"
      Slack.RtmApi.stop(state.rtm, reason)
    end

  end

  defp handle_message("build " <> commit_or_branch, message, state) do
    reply = Map.take(message, ["channel"])
      |> Map.put("type", "message")

    if state.build do

      reply = Map.put(reply, "text", "Build in progress already!")
      Slack.RtmApi.reply(state.rtm, reply)
      state

    else
      case FarmbotSlackbot.GitHub.get "/repos/farmbot/farmbot_os/commits?sha=#{commit_or_branch}" do
        {:ok, %{status_code: 200}} ->
          reply = Map.put(reply, "text", "Going to  build: https://github.com/farmbot/farmbot_os/tree/#{commit_or_branch}") |> Map.put("thread_ts", message["ts"])
          callback_pid = self()
          spawn_link FarmbotSlackbot.FirmwareBuilder, :full_build, [callback_pid, message["channel"], commit_or_branch]
          Slack.RtmApi.reply(state.rtm, reply)
          %{state | build: message["channel"], thread_ts: message["ts"]}

        _ ->
          reply = Map.put(reply, "text", "Could not find commit: #{commit_or_branch}")
          Slack.RtmApi.reply(state.rtm, reply)
          state
      end
    end

  end

  defp handle_message(text, message, state) do
    reply = Map.take(message, ["channel"])
      |> Map.put("type", "message")
      |> Map.put("text", format_text(text))
    Slack.RtmApi.reply(state.rtm, reply)
    state
  end

  defp format_text(text) do
    text
    |> String.replace("you", "_*you*_")
  end
end
