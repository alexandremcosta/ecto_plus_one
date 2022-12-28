ExUnit.start()

alias EctoPlusOne.Repo

{:ok, _pid} = Repo.start_link()

Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)
