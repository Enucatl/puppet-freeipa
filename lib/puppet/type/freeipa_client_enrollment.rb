# frozen_string_literal: true

Puppet::Type.newtype(:freeipa_client_enrollment) do
  @doc = 'Enroll a host with FreeIPA without placing credentials in a script.'

  ensurable do
    newvalue(:present) { provider.create }

    def retrieve
      provider.exists? ? :present : :absent
    end
  end

  newparam(:name, namevar: true)

  newparam(:domain) do
    validate { |value| raise ArgumentError, 'domain must not be empty' if value.empty? }
  end

  newparam(:server) do
    validate { |value| raise ArgumentError, 'server must not be empty' if value.empty? }
  end

  newparam(:principal) do
    validate { |value| raise ArgumentError, 'principal must not be empty' if value.empty? }
  end

  newparam(:password) do
    sensitive true
  end

  newparam(:mkhomedir, boolean: true, parent: Puppet::Parameter::Boolean)
  newparam(:hostname)

  newparam(:install_timeout) do
    munge(&:to_i)
    validate do |value|
      raise ArgumentError, 'install_timeout must be between 60 and 3600 seconds' unless value.to_i.between?(60, 3600)
    end
  end
end
