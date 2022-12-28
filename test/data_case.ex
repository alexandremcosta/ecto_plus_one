defmodule EctoPlusOne.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias EctoPlusOne.Repo

      import Ecto
      import Ecto.Query
      import EctoPlusOne.DataCase
    end
  end

  setup _ do
    :ok =  Ecto.Adapters.SQL.Sandbox.checkout(EctoPlusOne.Repo)
    :ok
  end
end
