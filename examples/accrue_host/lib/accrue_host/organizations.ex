defmodule AccrueHost.Organizations do
  use Sigra.Organizations,
    repo: AccrueHost.Repo,
    schemas: [
      organization: AccrueHost.Accounts.Organization,
      membership: AccrueHost.Accounts.OrganizationMembership,
      invitation: AccrueHost.Accounts.OrganizationInvitation,
      user_session: AccrueHost.Accounts.UserSession,
      organization_slug_alias: AccrueHost.Accounts.OrganizationSlugAlias,
      user: AccrueHost.Accounts.User,
      scope: AccrueHost.Accounts.Scope
    ]
end
