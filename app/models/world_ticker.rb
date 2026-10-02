class WorldTicker
  KEY = "homestead_world_ticker"

  def self.start
    return unless Rails.env.development?
    return unless Rails.application.config.active_job.queue_adapter == :async

    wrote = Rails.cache.write(KEY, true, expires_in: 45.seconds, unless_exist: true)
    AdvanceHomesteadsJob.set(wait: 2.seconds).perform_later if wrote
  end
end
