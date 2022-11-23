defmodule EctoPlusOne.Post do
  use Ecto.Schema

  import Ecto.Changeset

  alias __MODULE__

  alias EctoPlusOne.User

  schema "posts" do
    field(:description, :string)

    belongs_to(:user, User)

    timestamps()
  end

  def changeset(%Post{} = post, params \\ %{}) do
    post
    |> cast(params, [:description, :user_id])
    |> validate_required([:description, :user_id])
  end
end
