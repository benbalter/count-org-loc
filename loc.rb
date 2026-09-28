# frozen_string_literal: true

require 'octokit'
require 'open3'
require 'uri'
require 'cliver'
require 'fileutils'
require 'tmpdir'
require 'dotenv'

if ARGV.count != 1
  puts 'Usage: script/count [ORG NAME]'
  exit 1
end

Dotenv.load

def cloc(*args)
  cloc_path = Cliver.detect! 'cloc'
  Open3.capture2e(cloc_path, *args)
end

tmp_dir = Dir.mktmpdir('count-org-loc')
at_exit { FileUtils.remove_entry(tmp_dir) }

# Enabling support for GitHub Enterprise
unless ENV['GITHUB_ENTERPRISE_URL'].nil?
  Octokit.configure do |c|
    c.api_endpoint = ENV['GITHUB_ENTERPRISE_URL']
  end
end

# Treat a blank GITHUB_TOKEN as unset. The Actions workflows set it from a
# secret that expands to an empty string when not configured, and sending an
# empty token gets a 401 instead of unauthenticated access to public repos.
def github_token
  token = ENV['GITHUB_TOKEN'].to_s.strip
  token unless token.empty?
end

client = Octokit::Client.new access_token: github_token
client.auto_paginate = true

owner = ARGV[0].strip
repos = if client.user(owner).type == 'Organization'
          client.organization_repositories(owner, type: 'sources')
        else
          client.repositories(owner, type: 'sources')
        end
puts "Found #{repos.count} repos. Counting..."

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

reports = []
repos.each do |repo|
  puts "Counting #{repo.name}..."

  destination = File.expand_path repo.name, tmp_dir
  report_file = File.expand_path "#{repo.name}.txt", tmp_dir

  clone_args = ['git', 'clone', '--depth', '1', '--quiet', repo.clone_url, destination]
  _output, status = Open3.capture2e git_env(repo.clone_url), *clone_args
  next unless status.exitstatus.zero?

  _output, cloc_status = cloc destination, '--quiet', "--report-file=#{report_file}"
  reports.push(report_file) if File.exist?(report_file) && cloc_status.success?
end

puts 'Done. Summing...'

output, _status = cloc '--sum-reports', *reports
puts output.gsub(%r{^#{Regexp.escape tmp_dir}/(.*)\.txt}) { Regexp.last_match(1) + ' ' * (tmp_dir.length + 5) }
