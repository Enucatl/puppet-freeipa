# frozen_string_literal: true

require 'spec_helper'

describe 'freeipa::client' do
  let(:params) do
    {
      domain: 'example.test',
      server: 'ipa.example.test',
      principal: 'puppet-enroller',
      password: sensitive('secret')
    }
  end

  context 'when running on Ubuntu 24.04' do
    let(:facts) do
      {
        os: { 'name' => 'Ubuntu', 'family' => 'Debian', 'release' => { 'full' => '24.04', 'major' => '24.04' } },
        kernel: 'Linux'
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_package('freeipa-client').with_ensure('installed') }
    it { is_expected.to contain_service('sssd').with(ensure: 'running', enable: true) }
    it { is_expected.to contain_package('freeipa-client').that_comes_before('Freeipa_client_enrollment[default]') }
    it { is_expected.to contain_freeipa_client_enrollment('default').that_comes_before('Service[sssd]') }

    it 'passes enrollment parameters without unwrapping the password' do
      is_expected.to contain_freeipa_client_enrollment('default').with(
        domain: 'example.test',
        server: 'ipa.example.test',
        principal: 'puppet-enroller',
        password: sensitive('secret'),
        mkhomedir: true,
        install_timeout: 1800
      )
    end
  end

  context 'when running on Ubuntu 26.04' do
    let(:facts) { { os: { 'name' => 'Ubuntu', 'release' => { 'full' => '26.04' } } } }

    it { is_expected.to compile }
  end

  context 'when running on an unsupported release' do
    let(:facts) { { os: { 'name' => 'Ubuntu', 'release' => { 'full' => '22.04' } } } }

    it { is_expected.to compile.and_raise_error(/supports only Ubuntu 24.04 and 26.04/) }
  end

  context 'when running on a non-Ubuntu operating system' do
    let(:facts) { { os: { 'name' => 'Debian', 'release' => { 'full' => '12' } } } }

    it { is_expected.to compile.and_raise_error(/supports only Ubuntu/) }
  end
end
