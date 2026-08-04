# frozen_string_literal: true

require 'puppetlabs_spec_helper/rake_tasks'

PuppetLint.configuration.relative = true

desc 'Run the externally provisioned privileged acceptance topology'
task :acceptance do
  command = ENV.fetch('FREEIPA_ACCEPTANCE_COMMAND')
  sh command
end
