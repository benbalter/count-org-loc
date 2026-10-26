# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/count_org_loc'

# Run the block with GITHUB_TOKEN set to value (nil unsets it), then restore it.
def with_token(value)
  original = ENV.fetch('GITHUB_TOKEN', nil)
  ENV['GITHUB_TOKEN'] = value
  yield
ensure
  ENV['GITHUB_TOKEN'] = original
end
