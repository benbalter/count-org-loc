# frozen_string_literal: true

require 'octokit'
require 'open3'
require 'cliver'
require 'fileutils'
require 'tmpdir'
require 'dotenv'
require_relative 'lib/count_org_loc'

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

client = Octokit::Client.new access_token: github_token
client.auto_paginate = true

owner = ARGV[0].strip
repos = list_repos(client, owner)
puts "Found #{repos.count} repos. Counting..."

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

if reports.empty?
  puts "No repositories with countable code found for #{owner}."
  exit 0
end

output, _status = cloc '--sum-reports', *reports
puts label_reports(output, tmp_dir)
