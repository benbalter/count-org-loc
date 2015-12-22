require 'octokit'
require 'open3'
require 'cliver'
require 'dotenv'

if ARGV.count != 1
  puts "Usage: script/count [ORG NAME]"
  exit 1
end

Dotenv.load

def cloc(*args)
  cloc_path = Cliver.detect! 'cloc'
  Open3.capture2e(cloc_path, *args)
end

tmp_dir = File.expand_path "./tmp", File.dirname(__FILE__)
FileUtils.rm_rf tmp_dir
FileUtils.mkdir_p tmp_dir

client = Octokit::Client.new access_token: ENV["GITHUB_TOKEN"]
Octokit.auto_paginate = true

repos = client.organization_repositories(ARGV[0].strip, type: 'sources')
puts "Found #{repos.count} repos. Counting..."

reports = []
repos.each do |repo|
  puts "Counting #{repo.name}..."

  destination = File.expand_path repo.name, tmp_dir
  report_file = File.expand_path "#{repo.name}.txt", tmp_dir

  clone_url = repo.clone_url
  clone_url = clone_url.sub "//", "//#{ENV["GITHUB_TOKEN"]}:x-oauth-basic@" if ENV["GITHUB_TOKEN"]
  output, status = Open3.capture2e "git", "clone", "--depth", "1", "--quiet", clone_url, destination
  next unless status.exitstatus == 0

  output, status = cloc destination, "--quiet", "--report-file=#{report_file}"
  reports.push(report_file) if File.exists?(report_file) && status.exitstatus == 0
end

puts "Done. Summing..."

output, status = cloc "--sum-reports", *reports
puts output.gsub(/^#{Regexp.escape tmp_dir}\/(.*)\.txt/)  { $1 + " " * (tmp_dir.length + 5) }
