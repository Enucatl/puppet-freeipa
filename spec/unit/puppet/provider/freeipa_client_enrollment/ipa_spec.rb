# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/freeipa_client_enrollment'
require 'puppet/provider/freeipa_client_enrollment/ipa'

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

  before do
    allow(File).to receive(:exist?).with(config_path).and_return(false)
  end

  it 'passes hostile values as literal argv entries' do
    result = instance_double(Puppet::Util::Execution::ProcessOutput, exitstatus: 0)
    expect(Puppet::Util::Execution).to receive(:execute).with(
      [
        '/usr/sbin/ipa-client-install', '--unattended', '--domain=Example.Test.',
        '--server=ipa.example.test', '--principal=enroller name',
        "--password=s p'a\\ss\n;$(touch /tmp/nope)", '--mkhomedir',
        '--hostname=client.example.test'
      ],
      failonfail: false, combine: true, timeout: 120
    ).and_return(result)
    provider.create
  end

  it 'omits optional flags when they are not requested' do
    minimal_resource = Puppet::Type.type(:freeipa_client_enrollment).new(
      name: 'default', ensure: :present, domain: 'example.test', server: 'ipa.example.test',
      principal: 'enroller', password: password, mkhomedir: false, install_timeout: 120
    )
    minimal_provider = described_class.new(minimal_resource)
    result = instance_double(Puppet::Util::Execution::ProcessOutput, exitstatus: 0)
    expect(Puppet::Util::Execution).to receive(:execute) do |argv, _options|
      expect(argv).not_to include('--mkhomedir')
      expect(argv.grep(/\A--hostname=/)).to be_empty
      result
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
    expect(Puppet::Util::Execution).not_to receive(:execute)
    expect { provider.exists? }.to raise_error(Puppet::Error, /Refusing to re-enroll/)
  end

  it 'redacts installer output and password on failure' do
    result = instance_double(Puppet::Util::Execution::ProcessOutput, exitstatus: 2, to_s: password.unwrap)
    allow(Puppet::Util::Execution).to receive(:execute).and_return(result)
    expect { provider.create }.to raise_error(Puppet::Error, /status 2.*redacted/)
  end

  it 'reports a sanitized timeout' do
    allow(Puppet::Util::Execution).to receive(:execute).and_raise(Timeout::Error, password.unwrap)
    expect { provider.create }.to raise_error(Puppet::Error, /timed out after 120 seconds.*redacted/)
  end

  it 'sanitizes execution exceptions' do
    allow(Puppet::Util::Execution).to receive(:execute).and_raise(Puppet::ExecutionFailure, password.unwrap)
    expect { provider.create }.to raise_error(Puppet::Error, /could not be executed.*redacted/)
  end
end
