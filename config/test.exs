import Config

config :ecto_plus_one, repo: EctoPlusOne.Repo

config :ecto_plus_one, ecto_repos: [EctoPlusOne.Repo]

config :ecto_plus_one, EctoPlusOne.Repo,
  database: "ecto_plus_one_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, backends: []
