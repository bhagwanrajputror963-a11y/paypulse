require 'active_support/core_ext/integer/time'

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.force_ssl = true

  config.logger = ActiveSupport::Logger.new($stdout)
                                       .tap { |logger| logger.formatter = ::Logger::Formatter.new }
                                       .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  config.log_tags = [:request_id]
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false

  # Railway's assigned public domain — and any *.railway.app subdomain.
  # Add more hosts via RAILS_ALLOWED_HOSTS=host1,host2 env var.
  config.hosts << 'paypulse-production.up.railway.app'
  config.hosts << /.*\.railway\.app\z/
  ENV.fetch('RAILS_ALLOWED_HOSTS', '').split(',').map(&:strip).reject(&:empty?).each do |host|
    config.hosts << host
  end
end
