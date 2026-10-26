# frozen_string_literal: true

require 'octokit'
require 'uri'

# Helpers for loc.rb, kept separate so they can be tested without running the
# script.

# Treat a blank GITHUB_TOKEN as unset. The Actions workflows set it from a
# secret that expands to an empty string when not configured, and sending an
# empty token gets a 401 instead of unauthenticated access to public repos.
def github_token
  token = ENV['GITHUB_TOKEN'].to_s.strip
  token unless token.empty?
end

# Login of the token's user, or nil when the token has no user identity (for
# example the Actions `github.token`, which gets a 403 on GET /user).
def authenticated_login(client)
  client.user.login
rescue Octokit::Forbidden, Octokit::Unauthorized
  nil
end

# List the repositories to count. `GET /users/{owner}/repos` only returns public
# repositories, so when counting the authenticated user's own account use
# `GET /user/repos` instead, which includes the private ones the token can read.
def list_repos(client, owner, authenticated: !github_token.nil?)
  return client.organization_repositories(owner, type: 'sources') if client.user(owner).type == 'Organization'

  if authenticated && authenticated_login(client)&.casecmp?(owner)
    client.repositories(nil, affiliation: 'owner').reject(&:fork)
  else
    # `type: 'sources'` only applies to the org endpoint, so filter forks here.
    client.repositories(owner).reject(&:fork)
  end
end

# Pass the token to git as an HTTP header via environment config rather than
# embedding it in the clone URL, where it would end up in .git/config, error
# messages, and the process list. The header is scoped to the clone URL's
# origin so it isn't sent to any other host.
def git_env(clone_url)
  return {} unless github_token

  origin = URI(clone_url)
  credentials = ["#{github_token}:x-oauth-basic"].pack('m0')
  {
    'GIT_CONFIG_COUNT' => '1',
    'GIT_CONFIG_KEY_0' => "http.#{origin.scheme}://#{origin.host}/.extraHeader",
    'GIT_CONFIG_VALUE_0' => "Authorization: Basic #{credentials}"
  }
end

# `cloc --sum-reports` labels each row with its report's path. Swap the temp dir
# prefix for the repo name, padding so the columns stay aligned.
def label_reports(output, tmp_dir)
  output.gsub(%r{^#{Regexp.escape tmp_dir}/(.*)\.txt}) { Regexp.last_match(1) + ' ' * (tmp_dir.length + 5) }
end
