# frozen_string_literal: true

require_relative 'test_helper'

class GithubTokenTest < Minitest::Test
  def test_unset_is_nil
    with_token(nil) { assert_nil github_token }
  end

  def test_blank_is_nil
    with_token("  \n") { assert_nil github_token }
  end

  def test_strips_whitespace
    with_token(" abc123\n") { assert_equal 'abc123', github_token }
  end
end

class GitEnvTest < Minitest::Test
  def test_no_token_sets_no_config
    with_token(nil) { assert_empty git_env('https://github.com/acme/widgets.git') }
  end

  def test_token_goes_in_a_header_scoped_to_the_clone_origin
    env = with_token('abc123') { git_env('https://github.com/acme/widgets.git') }

    assert_equal '1', env['GIT_CONFIG_COUNT']
    assert_equal 'http.https://github.com/.extraHeader', env['GIT_CONFIG_KEY_0']
    assert_equal "Authorization: Basic #{['abc123:x-oauth-basic'].pack('m0')}", env['GIT_CONFIG_VALUE_0']
  end

  def test_enterprise_host_scopes_to_that_host
    env = with_token('abc123') { git_env('https://ghe.example.com/acme/widgets.git') }
    assert_equal 'http.https://ghe.example.com/.extraHeader', env['GIT_CONFIG_KEY_0']
  end

  def test_token_never_appears_in_plain_text
    env = with_token('abc123') { git_env('https://github.com/acme/widgets.git') }
    refute(env.values.any? { |v| v.include?('abc123') })
  end
end

class LabelReportsTest < Minitest::Test
  def test_replaces_report_paths_with_repo_names_keeping_columns_aligned
    tmp_dir = '/tmp/count-org-loc-x'
    output = <<~OUT
      #{tmp_dir}/widgets.txt          12        3       40
      #{tmp_dir}/gadgets.txt           1        0        2
      SUM:                                           13        3       42
    OUT

    lines = label_reports(output, tmp_dir).lines

    assert_match(/\Awidgets +12/, lines[0])
    assert_match(/\Agadgets +1/, lines[1])
    assert_equal output.lines.map(&:length), lines.map(&:length)
  end
end
