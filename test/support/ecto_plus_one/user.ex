defmodule EctoPlusOne.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  alias EctoPlusOne.Post

  schema "users" do
    field(:name, :string)

    has_many(:posts, Post)

    timestamps()
  end

  def changeset(%User{} = user, params \\ %{}) do
    user
    |> cast(params, [:name])
    |> validate_required([:name])
  end
end
