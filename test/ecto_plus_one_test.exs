defmodule EctoPlusOneTest do
  use ExUnit.Case
  use EctoPlusOne.DataCase

  import Ecto.Query
  import ExUnit.CaptureLog

  alias EctoPlusOne.User
  alias EctoPlusOne.Post

  @repo Application.get_env(:ecto_plus_one, :repo)

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(EctoPlusOne.Repo)

    {:ok, user1} = create_user(%{name: "test1"})
    {:ok, user2} = create_user(%{name: "test2"})
    {:ok, user3} = create_user(%{name: "test3"})

    for _ <- 1..10, do: create_post(%{user_id: user1.id, description: "test post"})
    for _ <- 1..10, do: create_post(%{user_id: user2.id, description: "test post"})
    for _ <- 1..10, do: create_post(%{user_id: user3.id, description: "test post"})

    EctoPlusOne.start([:ecto_plus_one, :repo, :query])
  end

  test "generates N+1 query" do
    from(p in Post)
    |> @repo.all()
    |> Enum.map(fn %{user_id: user_id} ->
      from(u in User, where: u.id == ^user_id)
      |> @repo.one()
    end)

    assert capture_log(fn ->
             # dummy query to trigger N+1
             from(u in User) |> @repo.all()
           end) =~ "[warning] N+1 Query Detected!"
  end

  defp create_user(params) do
    %User{}
    |> User.changeset(params)
    |> @repo.insert()
  end

  defp create_post(params) do
    %Post{}
    |> Post.changeset(params)
    |> @repo.insert()
  end
end
