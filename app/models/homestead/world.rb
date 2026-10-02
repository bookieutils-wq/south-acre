class Homestead::World
  WINDOW = 12.hours
  WEATHER_SPAN = 10.minutes
  RAIN_BONUS = 30
  DRY_PENALTY = 15
  GIFT_RATE = 0.03
  CROW_RATE = 0.045
  PURSE_RATE = 0.055
  KEPT_EVENTS = 24

  def initialize(homestead, now:, rng:)
    @homestead = homestead
    @now = now
    @rng = rng
    @changed = false
  end

  def apply
    missed = ((now - tick_from) / 60).floor
    return false if missed < 1

    steps = [ missed, WINDOW.in_minutes.to_i ].min
    @plots = homestead.plots.to_a

    steps.times do |index|
      moment = now - (steps - index - 1).minutes
      roll_weather(moment)
      apply_growth(moment)
      roll_event(moment)
    end

    homestead.last_ticked_at = now
    homestead.save!
    @plots.each { |plot| plot.save! if plot.changed? }
    trim_events
    homestead.world_events.reset
    @changed
  end

  private
    attr_reader :homestead, :now, :rng

    def tick_from
      homestead.last_ticked_at || homestead.created_at
    end

    def roll_weather(moment)
      return if homestead.weather_until.present? && homestead.weather_until > moment

      rolled = %w[clear clear rain dry][rng.rand(4)]
      if rolled != homestead.weather
        homestead.weather = rolled
        log("weather", weather_message(rolled), moment)
      end
      homestead.weather_until = moment + WEATHER_SPAN
    end

    def weather_message(rolled)
      case rolled
      when "rain" then "Rain moved in over the acre."
      when "dry" then "A dry spell settled on the field."
      else "The sky cleared."
      end
    end

    def apply_growth(moment)
      delta = growth_delta
      return if delta.zero?

      @plots.each do |plot|
        @changed = true if plot.absorb_growth(moment, delta)
      end
    end

    def growth_delta
      case homestead.weather
      when "rain" then RAIN_BONUS
      when "dry" then -DRY_PENALTY
      else 0
      end
    end

    def roll_event(moment)
      roll = rng.rand
      if roll < GIFT_RATE
        leave_coins(moment, 2 + rng.rand(4), "gift", "A neighbor left %d coins on the gatepost.")
      elsif roll < CROW_RATE
        spoil_a_crop(moment)
      elsif roll < PURSE_RATE
        leave_coins(moment, 4 + rng.rand(5), "purse", "You found %d coins tucked in the grass.")
      end
    end

    def leave_coins(moment, amount, kind, template)
      homestead.coins += amount
      log(kind, format(template, amount), moment)
    end

    def spoil_a_crop(moment)
      victims = @plots.select { |plot| plot.ripe_before?(moment - 1.minute) }
      return if victims.empty?

      victim = victims[rng.rand(victims.length)]
      victim.spoiled = true
      log("crow", "Crows ruined the #{victim.crop.name.downcase} left ripe on bed #{victim.position + 1}.", moment)
    end

    def log(kind, message, moment)
      homestead.world_events.build(kind:, message:, happened_at: moment)
      @changed = true
    end

    def trim_events
      stale_ids = homestead.world_events.offset(KEPT_EVENTS).ids
      WorldEvent.where(id: stale_ids).delete_all if stale_ids.any?
    end
end
