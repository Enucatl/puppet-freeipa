# frozen_string_literal: true

require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |config|
  config.default_facts = {
    puppetversion: Puppet.version
  }
  config.before do
    Puppet.settings[:strict] = :warning
  end
end

def sensitive(value)
  Puppet::Pops::Types::PSensitiveType::Sensitive.new(value)
end
