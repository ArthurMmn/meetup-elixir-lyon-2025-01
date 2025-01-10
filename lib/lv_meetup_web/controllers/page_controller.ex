defmodule LvMeetupWeb.PageController do
  use LvMeetupWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def maintenance(conn, _params) do
    render(conn, :maintenance)
  end
end
