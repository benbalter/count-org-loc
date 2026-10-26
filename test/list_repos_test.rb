# frozen_string_literal: true

require_relative 'test_helper'

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
        raise @identity if @identity.is_a?(Class)
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
    repos = list_repos(client, 'me', authenticated: true)
    assert_equal [[:repositories, 'me']], client.calls
    assert_equal ['a'], repos.map(&:name)
  end

  def test_other_user_keeps_public_listing
    client = FakeClient.new(login: 'me')
    repos = list_repos(client, 'someone', authenticated: true)
    assert_equal [[:repositories, 'someone']], client.calls
    assert_equal ['a'], repos.map(&:name)
  end

  def test_unauthenticated_keeps_public_listing
    client = FakeClient.new(login: 'me')
    repos = list_repos(client, 'me', authenticated: false)
    assert_equal [[:repositories, 'me']], client.calls
    assert_equal ['a'], repos.map(&:name)
  end

  def test_unauthorized_token_falls_back_to_public_listing
    client = FakeClient.new(login: 'me', identity: Octokit::Unauthorized)
    list_repos(client, 'me', authenticated: true)
    assert_equal [[:repositories, 'me']], client.calls
  end

  def test_without_token_skips_the_authenticated_lookup
    client = FakeClient.new(login: 'me')
    def client.user(name = nil)
      raise 'GET /user should not be called without a token' if name.nil?

      super
    end
    with_token(nil) { list_repos(client, 'me') }
    assert_equal [[:repositories, 'me']], client.calls
  end

  def test_org_unchanged
    client = FakeClient.new(login: 'me', type: 'Organization')
    list_repos(client, 'acme', authenticated: true)
    assert_equal [[:organization_repositories, 'acme', { type: 'sources' }]], client.calls
  end
end
