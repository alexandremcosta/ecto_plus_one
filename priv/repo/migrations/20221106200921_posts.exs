defmodule EctoPlusOne.Repo.Migrations.Posts do
  use Ecto.Migration

  def change do
    create table("posts") do
      add(:description, :string)
      add(:user_id, references(:users))

      timestamps()
    end
  end
end
