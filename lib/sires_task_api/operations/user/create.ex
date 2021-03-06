defmodule SiresTaskApi.User.Create do
  use SiresTaskApi.Operation,
    params: %{
      user!: %{
        email!: :string,
        password!: :string,
        role: :string,
        first_name: :string,
        middle_name: :string,
        last_name: :string,
        position: :string,
        avatar: SiresTaskApi.Attachment,
        locale: :string
      }
    }

  alias SiresTaskApi.{Repo, User, Project}

  defdelegate validate_params(changeset), to: User.SharedHelpers

  def build(op) do
    op
    |> step(:create_project, fn _ -> create_project(op.params) end)
    |> step(:create_user, &create_user(op.params.user, &1.create_project))
    |> step(:create_member, &create_member(&1.create_user, &1.create_project))
    |> step(:upload_avatar, fn %{create_user: user} ->
      user |> User.SharedHelpers.upload_avatar(op.params.user[:avatar])
    end)
  end

  defp create_project(params) do
    locale = params[:locale] || Gettext.get_locale(SiresTaskApi.Gettext)

    Gettext.with_locale(SiresTaskApi.Gettext, locale, fn ->
      %Project{name: Gettext.gettext(SiresTaskApi.Gettext, "Inbox")} |> Repo.insert()
    end)
  end

  defp create_user(params, project) do
    %User{inbox_project: project}
    |> User.SharedHelpers.changeset(params)
    |> Repo.insert()
  end

  defp create_member(user, project) do
    %Project.Member{user: user, project: project, role: "admin"}
    |> Repo.insert()
  end
end
