defmodule Yachanakuy.Repo do
  use Ecto.Repo,
    otp_app: :yachanakuy,
    adapter: Ecto.Adapters.SQLite3
end
