defmodule EctoPlusOne.Repo do
  use Ecto.Repo,
    otp_app: :ecto_plus_one,
    adapter: Ecto.Adapters.Postgres
end
