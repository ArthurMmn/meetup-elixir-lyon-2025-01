defmodule LvMeetupWeb.ScrabbleAdminLive do
  @moduledoc false

  use LvMeetupWeb, :live_view

  alias LvMeetup.HistoryPubsub

  @checked_module LvMeetupWeb.ScrabbleCheckerLive

  def render(assigns) do
    ~H"""
    <main class="mx-auto">
      <div>
        <.button phx-click="maintenance">C'est l'heure de la maintenance !</.button>
      </div>
      <div class="grid grid-cols-2 gap-5">
        <div>
          <p class="p-2 text-lg">Liste des process</p>
          <ul id="processes">
            <li :for={pid <- @processes}>
              <details>
                <summary>{format_pid(pid)}</summary>
                <div class="text-xs whitespace-pre-wrap">{get_pid_state(pid)}</div>
              </details>
            </li>
          </ul>
        </div>
        <div>
          <p class="p-2 text-lg">Historique des messages</p>
          <ul id="messages" phx-update="stream">
            <li :for={{dom_id, msg} <- @streams.messages} id={dom_id}>
              {msg.msg}
            </li>
          </ul>
        </div>
      </div>
    </main>
    """
  end

  defp format_pid(pid) when is_pid(pid) do
    :erlang.pid_to_list(pid) |> Enum.join("-")
  end

  defp get_pid_state(pid) do
    inspect(:sys.get_state(pid), pretty: true)
  end

  def mount(_, _, socket) do
    processes =
      :erlang.processes()
      |> Enum.filter(fn pid ->
        case :erlang.process_info(pid, :dictionary) do
          {:dictionary, dict} ->
            Enum.any?(dict, fn
              {:"$initial_call", {module, _, _}} when module == @checked_module -> true
              _ -> false
            end)

          _ ->
            false
        end
      end)

    HistoryPubsub.subscribe()

    socket =
      socket
      |> assign(:processes, processes)
      |> stream(:messages, [])

    {:ok, socket}
  end

  def handle_event("maintenance", _, socket) do
    Enum.each(socket.assigns.processes, &send(&1, {:admin, :maintenance}))

    {:noreply, socket}
  end

  def handle_info({"Elixir.LvMeetup.HistoryPubsub", msg}, socket) do
    socket =
      socket
      |> stream_insert(:messages, msg)

    {:noreply, socket}
  end
end
