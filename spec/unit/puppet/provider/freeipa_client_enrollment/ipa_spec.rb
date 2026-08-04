# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'puppet/type/freeipa_client_enrollment'
require 'puppet/provider/freeipa_client_enrollment/ipa'

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe Puppet::Type.type(:freeipa_client_enrollment).provider(:ipa) do
  let(:password) { sensitive("s p'a\\ss\n;$(touch /tmp/nope)") }
  let(:resource) do
    Puppet::Type.type(:freeipa_client_enrollment).new(
      name: 'default',
      ensure: :present,
      domain: 'Example.Test.',
      server: 'ipa.example.test',
      principal: 'enroller name',
      password: password,
      mkhomedir: true,
      hostname: 'client.example.test',
      install_timeout: 120
    )
  end
  let(:provider) { described_class.new(resource) }
  let(:config_path) { described_class::CONFIG_PATH }
  let(:stdin) { instance_double(IO, write: nil, close: nil) }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:exit_status) { instance_double(Process::Status, exitstatus: 0) }
  # Open3 adds #pid dynamically to the wait thread instance.
  # rubocop:disable RSpec/VerifiedDoubles
  let(:wait_thread) { double('wait thread', join: true, value: exit_status, pid: 1234) }
  # rubocop:enable RSpec/VerifiedDoubles

  before do
    allow(File).to receive(:exist?).with(config_path).and_return(false)
  end

  it 'passes hostile values as literal argv entries and stdin data' do
    expect(Open3).to receive(:popen3).with(
      '/usr/sbin/ipa-client-install', '--unattended', '--domain=Example.Test.',
      '--server=ipa.example.test', '--principal=enroller name',
      "--password=s p'a\\ss\n;$(touch /tmp/nope)", '--mkhomedir', '--hostname=client.example.test'
    ).and_return([stdin, stdout, stderr, wait_thread])
    expect(stdin).to receive(:write).with(password.unwrap)
    expect(stdin).to receive(:write).with("\n")
    expect(stdin).to receive(:close)
    provider.create
  end

  it 'omits optional flags when they are not requested' do
    minimal_resource = Puppet::Type.type(:freeipa_client_enrollment).new(
      name: 'default', ensure: :present, domain: 'example.test', server: 'ipa.example.test',
      principal: 'enroller', password: password, mkhomedir: false, install_timeout: 120
    )
    minimal_provider = described_class.new(minimal_resource)
    allow(Open3).to receive(:popen3) do |*argv|
      expect(argv).not_to include('--mkhomedir')
      expect(argv.grep(/\A--hostname=/)).to be_empty
      [stdin, stdout, stderr, wait_thread]
    end
    minimal_provider.create
  end

  it 'is absent when configuration is missing' do
    expect(provider.exists?).to be(false)
  end

  it 'normalizes and accepts matching configuration' do
    config = [
      "[global]\n",
      "domain = example.test\n",
      "server = IPA.EXAMPLE.TEST.\n",
      "host = CLIENT.EXAMPLE.TEST.\n"
    ]
    allow(File).to receive(:exist?).with(config_path).and_return(true)
    allow(File).to receive(:readlines).and_return(config)
    expect(provider.exists?).to be(true)
  end

  it 'rejects malformed configuration' do
    allow(File).to receive(:exist?).with(config_path).and_return(true)
    allow(File).to receive(:readlines).and_return(["domain=example.test\n"])
    expect { provider.exists? }.to raise_error(Puppet::Error, /malformed.*server/)
  end

  it 'rejects mismatch without executing anything' do
    config = ["domain=other.test\n", "server=ipa.example.test\n", "host=client.example.test\n"]
    allow(File).to receive(:exist?).with(config_path).and_return(true)
    allow(File).to receive(:readlines).and_return(config)
    expect(Open3).not_to receive(:popen3)
    expect { provider.exists? }.to raise_error(Puppet::Error, /Refusing to re-enroll/)
  end

  it 'redacts installer output and password on failure' do
    failed_status = instance_double(Process::Status, exitstatus: 2)
    allow(wait_thread).to receive(:value).and_return(failed_status)
    allow(Open3).to receive(:popen3).and_return([stdin, stdout, stderr, wait_thread])
    expect { provider.create }.to raise_error(Puppet::Error, /status 2.*redacted/)
  end

  it 'reports a sanitized timeout' do
    allow(wait_thread).to receive(:join).with(120).and_return(false)
    allow(wait_thread).to receive(:join).with(5).and_return(true)
    allow(Open3).to receive(:popen3).and_return([stdin, stdout, stderr, wait_thread])
    allow(Process).to receive(:kill)
    expect { provider.create }.to raise_error(Puppet::Error, /timed out after 120 seconds.*redacted/)
  end

  it 'sanitizes execution exceptions' do
    allow(Open3).to receive(:popen3).and_raise(StandardError, password.unwrap)
    expect { provider.create }.to raise_error(Puppet::Error, /could not be executed.*redacted/)
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
