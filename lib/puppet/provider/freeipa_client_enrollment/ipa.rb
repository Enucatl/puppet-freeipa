# frozen_string_literal: true

require 'puppet/util/execution'
require 'timeout'

Puppet::Type.type(:freeipa_client_enrollment).provide(:ipa) do
  desc 'Enroll a FreeIPA client using ipa-client-install directly.'

  confine kernel: :linux
  defaultfor osfamily: :debian

  def exists?
    return false unless File.exist?(self.class::CONFIG_PATH)

    config = read_config
    required = { 'domain' => resource[:domain], 'server' => resource[:server] }
    required['host'] = resource[:hostname] if resource[:hostname]

    missing = required.keys.reject { |key| config.key?(key) && !config[key].empty? }
    unless missing.empty?
      raise Puppet::Error, "Existing FreeIPA configuration is malformed: missing #{missing.join(', ')}"
    end

    mismatches = required.filter_map do |key, requested|
      actual = config[key]
      "#{key}=#{actual.inspect} (requested #{requested.inspect})" unless normalize(actual) == normalize(requested)
    end
    unless mismatches.empty?
      message = "Existing FreeIPA enrollment does not match: #{mismatches.join(', ')}."
      raise Puppet::Error, "#{message} Refusing to re-enroll."
    end

    true
  rescue Errno::EACCES, Errno::EISDIR, IOError
    raise Puppet::Error, 'Unable to read existing FreeIPA configuration'
  end

  def create
    result = execute_installer
    return if result.exitstatus.zero?

    raise Puppet::Error,
          "FreeIPA client enrollment failed with exit status #{result.exitstatus}; installer output was redacted"
  end

  def execute_installer
    Puppet::Util::Execution.execute(
      install_command,
      failonfail: false,
      combine: true,
      timeout: resource[:install_timeout]
    )
  rescue Timeout::Error
    raise Puppet::Error,
          "FreeIPA client enrollment timed out after #{resource[:install_timeout]} seconds; output was redacted"
  rescue StandardError
    raise Puppet::Error, 'FreeIPA client enrollment could not be executed; command details and output were redacted'
  end

  def destroy
    raise Puppet::Error, 'FreeIPA enrollment removal is not supported'
  end

  private

  def read_config
    File.readlines(self.class::CONFIG_PATH, chomp: true).each_with_object({}) do |line, values|
      next if line.match?(/\A\s*(?:#|;|\[|\z)/)

      key, value = line.split('=', 2)
      next unless value

      values[key.strip.downcase] = value.strip
    end
  end

  def normalize(value)
    value.to_s.strip.downcase.sub(/\.\z/, '')
  end

  def install_command
    command = [
      self.class::INSTALLER,
      '--unattended',
      "--domain=#{resource[:domain]}",
      "--server=#{resource[:server]}",
      "--principal=#{resource[:principal]}",
      "--password=#{unwrap_password}"
    ]
    command << '--mkhomedir' if resource[:mkhomedir]
    command << "--hostname=#{resource[:hostname]}" if resource[:hostname]
    command
  end

  def unwrap_password
    password = resource[:password]
    password.respond_to?(:unwrap) ? password.unwrap : password
  end
end

Puppet::Type.type(:freeipa_client_enrollment).provider(:ipa).const_set(:CONFIG_PATH, '/etc/ipa/default.conf')
Puppet::Type.type(:freeipa_client_enrollment).provider(:ipa).const_set(:INSTALLER, '/usr/sbin/ipa-client-install')
