defmodule LvMeetupWeb.ScrabbleFuzzyLive do
  @moduledoc false

  use LvMeetupWeb, :live_view

  alias LvMeetup.Scrabble
  alias LvMeetup.HistoryPubsub

  def render(assigns) do
    ~H"""
    <main class="mx-auto grid grid-cols-2 gap-5">
      <div id="fuzzy" phx-hook="FuzzyMatchHook" data-list={Jason.encode!(Scrabble.all())}>
        <div>
          <.input name="text" type="text" placeholder="Mots contenant ..." value="" fuzzy-input />
        </div>
        <ul class="flex gap-1 flex-wrap text-xs mt-2" fuzzy-wrapper></ul>
      </div>
      <div
        :if={@score}
        class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 p-2"
      >
        <span :if={Keyword.fetch!(@score, :status) == :ok} class="text-green-600">
          Le mot <strong>{Keyword.fetch!(@score, :word)}</strong>
          vaut <strong>{Keyword.fetch!(@score, :score)}</strong>
          points.
        </span>
        <span :if={Keyword.fetch!(@score, :status) == :error} class="text-red-600">
          Le mot <strong>{Keyword.fetch!(@score, :word)}</strong> est invalide.
        </span>
      </div>
    </main>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:words, [])

    {:ok, socket}
  end

  def handle_event("search", %{"mot" => word}, socket) do
    socket =
      socket
      |> push_patch(to: ~p"/fuzzy-scrabble?mot=#{word}")

    {:noreply, socket}
  end

  def handle_params(%{"mot" => mot}, _, socket) do
    score = Scrabble.result(mot)

    process_name =
      self()
      |> :erlang.pid_to_list()
      |> Enum.join("-")

    HistoryPubsub.publish(%{
      id: :erlang.unique_integer(),
      msg: "#{process_name} a recherché #{mot}"
    })

    {:noreply, assign(socket, :score, score)}
  end

  def handle_params(_, _, socket) do
    {:noreply, assign(socket, :score, nil)}
  end

  def handle_info({:admin, :maintenance}, socket) do
    socket =
      socket
      |> redirect(to: ~p"/maintenance")
      |> put_flash(:error, "Maintenance en cours. Merci de votre compréhension")

    {:noreply, socket}
  end
end
