defmodule LvMeetup.Repo do
  use Ecto.Repo,
    otp_app: :lv_meetup,
    adapter: Ecto.Adapters.Postgres
end
