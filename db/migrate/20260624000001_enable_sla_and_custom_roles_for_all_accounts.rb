class EnableSlaAndCustomRolesForAllAccounts < ActiveRecord::Migration[7.0]
  def up
    enabled_features = %w[sla custom_roles]
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')

    if config&.value.present?
      features = config.value.map do |feature|
        enabled_features.include?(feature['name']) ? feature.merge('enabled' => true).except('premium') : feature.except('premium')
      end
      config.update!(value: features)
    end

    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.enable_features!(*enabled_features) }
    end
  end

  def down
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')

    if config&.value.present?
      features = config.value.map do |feature|
        %w[sla custom_roles].include?(feature['name']) ? feature.merge('enabled' => false) : feature
      end
      config.update!(value: features)
    end
  end
end
