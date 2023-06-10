# frozen_string_literal: true

require 'octokit'
require 'open3'
require 'cliver'
require 'fileutils'
require 'dotenv'

Dotenv.load

def cloc(*args)
  cloc_path = Cliver.detect! 'cloc'
  Open3.capture2e(cloc_path, *args)
end

tmp_dir = File.expand_path './tmp', File.dirname(__FILE__)
FileUtils.rm_rf tmp_dir
FileUtils.mkdir_p tmp_dir

# Enabling support for GitHub Enterprise
unless ENV['GITHUB_ENTERPRISE_URL'].nil?
  Octokit.configure do |c|
    c.api_endpoint = ENV['GITHUB_ENTERPRISE_URL']
  end
end

client = Octokit::Client.new access_token: ENV['GITHUB_TOKEN']
client.auto_paginate = true

repos=File.readlines('repositories.cfg')

reports = []
repos.each do |repo|
  repo=repo.strip
  puts "Counting #{repo}..."
  destination = File.expand_path repo, tmp_dir
  report_file = File.expand_path "#{repo}.txt", tmp_dir

  clone_url = "https://github.com/ZscalerCWP/#{repo}.git"
  clone_url = clone_url.sub '//', "//#{ENV['GITHUB_TOKEN']}:x-oauth-basic@" if ENV['GITHUB_TOKEN']
  _output, status = Open3.capture2e 'git', 'clone', '--depth', '1', '--quiet', clone_url, destination
  next unless status.exitstatus.zero?
  cd #{repo}
  git log --shortstat --since "8/5/2023" --until "today" | grep "files changed" | awk '{files+=$1; inserted+=$4; deleted+=$6} END {print "files changed", files, "lines inserted:", inserted, "lines deleted:", deleted}'
  _output, _status = cloc destination, '--quiet', "--report-file=#{report_file}"
end

puts 'Done. Summing...'

output, _status = cloc '--sum-reports', *reports
puts output.gsub(%r{^#{Regexp.escape tmp_dir}/(.*)\.txt}) { Regexp.last_match(1) + ' ' * (tmp_dir.length + 5) }
