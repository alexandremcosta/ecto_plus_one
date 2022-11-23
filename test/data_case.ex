defmodule EctoPlusOne.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Ecto.Changeset
      import EctoPlusOne.DataCase
      alias EctoPlusOne.Repo
    end
  end

  setup _ do
    Ecto.Adapters.SQL.Sandbox.mode(EctoPlusOne.Repo, :manual)
  end
end
