class Plot < ApplicationRecord
  belongs_to :homestead, inverse_of: :plots

  validates :position, presence: true, uniqueness: { scope: :homestead_id }
  validates :bonus_seconds, numericality: { only_integer: true }

  def crop
    Crop.find(crop_key) if crop_key.present?
  end

  def empty?
    crop_key.blank? && !spoiled?
  end

  def ready?
    crop.present? && !spoiled? && raw_elapsed >= crop.seconds
  end

  def growing?
    crop.present? && !spoiled? && !ready?
  end

  def state
    return "empty" if empty?
    return "spoiled" if spoiled?
    return "ready" if ready?

    "growing"
  end

  def stage
    return state unless growing?

    if progress < 0.25
      "seed"
    elsif progress < 0.55
      "sprout"
    elsif progress < 0.85
      "leaf"
    else
      "ripe"
    end
  end

  def progress
    return 0 unless crop

    [ raw_elapsed / crop.seconds, 1.0 ].min.clamp(0, 1)
  end

  def seconds_remaining
    return 0 unless growing?

    [ crop.seconds - raw_elapsed, 0 ].max.ceil
  end

  def ready_at
    return unless planted_at && crop

    planted_at + crop.seconds - bonus_seconds
  end

  def ripened_since?(seen_at)
    ready? && ready_at.present? && seen_at.present? && ready_at > seen_at && ready_at <= Time.current
  end

  def elapsed_at(moment)
    moment - planted_at + bonus_seconds
  end

  def absorb_growth(moment, delta)
    return false if planted_at.blank? || crop.nil? || spoiled? || moment <= planted_at
    return false if elapsed_at(moment) >= crop.seconds

    self.bonus_seconds += delta
    true
  end

  def ripe_before?(moment)
    planted_at.present? && crop.present? && !spoiled? && elapsed_at(moment) >= crop.seconds
  end

  def plant(key)
    sown = Crop.find(key)
    unless sown
      errors.add(:base, "Choose a seed from the shed.")
      return
    end

    homestead.with_lock do
      reload
      homestead.reload
      if spoiled?
        errors.add(:base, "Clear this bed before planting again.")
      elsif crop_key.present?
        errors.add(:base, "That bed is already planted.")
      elsif homestead.coins < sown.seed_cost
        errors.add(:base, "#{sown.name} seed costs #{sown.seed_cost} coins.")
      else
        homestead.update!(coins: homestead.coins - sown.seed_cost)
        update!(crop_key: sown.key, planted_at: Time.current, bonus_seconds: 0, spoiled: false)
        return sown
      end
    end
    nil
  end

  def harvest
    homestead.with_lock do
      reload
      homestead.reload
      unless ready?
        errors.add(:base, "That crop isn't ready to pick.")
        next
      end

      value = crop.harvest_value
      homestead.update!(coins: homestead.coins + value)
      reset_bed!
      return value
    end
    nil
  end

  def clear_bed
    unless spoiled?
      errors.add(:base, "This bed doesn't need clearing.")
      return
    end

    reset_bed!
    true
  end

  private
    def raw_elapsed
      return 0 unless planted_at

      Time.current - planted_at + bonus_seconds
    end

    def reset_bed!
      update!(crop_key: nil, planted_at: nil, bonus_seconds: 0, spoiled: false)
    end
end
