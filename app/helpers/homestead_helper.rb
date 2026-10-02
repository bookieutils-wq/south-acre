module HomesteadHelper
  def format_duration(seconds)
    total = [ seconds.to_i, 0 ].max
    hours, remainder = total.divmod(3600)
    minutes, secs = remainder.divmod(60)

    if hours.positive?
      minutes.positive? ? "#{hours}h #{minutes}m" : "#{hours}h"
    elsif minutes.positive?
      secs.positive? ? "#{minutes}m #{secs}s" : "#{minutes}m"
    else
      "#{secs}s"
    end
  end

  def plant_label(homestead, crop)
    if homestead.plots.none?(&:empty?)
      "Beds full"
    elsif homestead.coins < crop.seed_cost
      "Need #{crop.seed_cost}"
    else
      "Plant"
    end
  end
end
