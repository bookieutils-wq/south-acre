class AdvanceHomesteadsJob < ApplicationJob
  queue_as :default

  def perform
    Homestead.find_each do |homestead|
      next unless homestead.advance_world!

      Turbo::StreamsChannel.broadcast_refresh_later_to(homestead)
    end
  ensure
    reschedule if Rails.env.development?
  end

  private
    def reschedule
      Rails.cache.write(WorldTicker::KEY, true, expires_in: 45.seconds)
      self.class.set(wait: 30.seconds).perform_later
    end
end
