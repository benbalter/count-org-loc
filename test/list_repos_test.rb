# frozen_string_literal: true

require 'minitest/autorun'
require 'octokit'

# loc.rb runs on load, so pull out just the helper under test.
SOURCE = File.read(File.expand_path('../loc.rb', __dir__))
SOURCE.scan(/^def (?:authenticated_login|list_repos).*?^end$/m).each { |src| eval(src) } # rubocop:disable Security/Eval

def github_token
  ENV.fetch('GITHUB_TOKEN', nil)
end

class ListReposTest < Minitest::Test
  Account = Struct.new(:login, :type)
  Repo = Struct.new(:name, :fork)

  class FakeClient
    attr_reader :calls

    def initialize(login:, type: 'User', identity: true)
      @login = login
      @type = type
      @identity = identity
      @calls = []
    end

    def user(name = nil)
      if name.nil?
        raise Octokit::Forbidden unless @identity

        return Account.new(@login)
      end

      Account.new(name, @type)
    end

    def repositories(*args)
      @calls << [:repositories, *args]
      [Repo.new('a', false), Repo.new('b', true)]
    end

    def organization_repositories(*args)
      @calls << [:organization_repositories, *args]
      []
    end
  end

  def test_own_account_uses_authenticated_endpoint_and_skips_forks
    client = FakeClient.new(login: 'Me')
    repos = list_repos(client, 'me', authenticated: true)
    assert_equal [[:repositories, nil, { affiliation: 'owner' }]], client.calls
    assert_equal ['a'], repos.map(&:name)
  end

  def test_token_without_user_identity_falls_back_to_public_listing
    client = FakeClient.new(login: 'me', identity: false)
    list_repos(client, 'me', authenticated: true)
    assert_equal [[:repositories, 'me', { type: 'sources' }]], client.calls
  end

  def test_other_user_keeps_public_listing
    client = FakeClient.new(login: 'me')
    list_repos(client, 'someone', authenticated: true)
    assert_equal [[:repositories, 'someone', { type: 'sources' }]], client.calls
  end

  def test_unauthenticated_keeps_public_listing
    client = FakeClient.new(login: 'me')
    list_repos(client, 'me', authenticated: false)
    assert_equal [[:repositories, 'me', { type: 'sources' }]], client.calls
  end

  def test_org_unchanged
    client = FakeClient.new(login: 'me', type: 'Organization')
    list_repos(client, 'acme', authenticated: true)
    assert_equal [[:organization_repositories, 'acme', { type: 'sources' }]], client.calls
  end
end
