defmodule LvMeetup.HistoryPubsub do
  @moduledoc false

  @pubsub LvMeetup.PubSub
  @topic "#{__MODULE__}"

  alias Phoenix.PubSub

  def subscribe do
    PubSub.subscribe(@pubsub, @topic)
  end

  def publish(%{id: _, msg: _} = message) do
    PubSub.broadcast(@pubsub, @topic, {@topic, message})
  end
end
