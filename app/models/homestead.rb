class Homestead < ApplicationRecord
  STARTING_PLOTS = 4
  MAX_PLOTS = 9
  PLOT_COSTS = { 4 => 26, 5 => 44, 6 => 70, 7 => 110, 8 => 160 }.freeze
  WEATHERS = {
    "clear" => [ "Clear", "Crops grow at their own pace." ],
    "rain" => [ "Rain", "Rain is feeding the beds, so growing crops rush ahead." ],
    "dry" => [ "Dry spell", "The soil is tight, so growing crops slow down." ]
  }.freeze

  has_many :plots, -> { order(:position) }, dependent: :destroy, inverse_of: :homestead
  has_many :world_events, -> { order(happened_at: :desc) }, dependent: :destroy, inverse_of: :homestead, autosave: true

  validates :name, presence: true, length: { in: 2..32 }
  validates :coins, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :weather, inclusion: { in: WEATHERS.keys }

  before_validation :strip_name

  def self.start!
    now = Time.current
    homestead = create!(
      name: "South Acre",
      coins: 20,
      weather: "clear",
      weather_until: now + 10.minutes,
      last_ticked_at: now,
      last_seen_at: now
    )
    STARTING_PLOTS.times { |position| homestead.plots.create!(position:) }
    homestead.world_events.create!(
      kind: "welcome",
      message: "You staked a claim on a quiet acre.",
      happened_at: now
    )
    homestead
  end

  def advance_world!(now: Time.current, rng: Random.new)
    changed = false
    with_lock do
      reload
      changed = Homestead::World.new(self, now:, rng:).apply
    end
    changed
  end

  def arrival_notes
    return [] if last_seen_at.blank? || Time.current - last_seen_at < 60

    notes = []
    ready_count = plots.count { |plot| plot.ripened_since?(last_seen_at) }
    if ready_count.positive?
      notes << "#{ready_count} #{'crop'.pluralize(ready_count)} finished growing."
    end

    world_events
      .select { |event| event.happened_at > last_seen_at && event.kind != "welcome" }
      .sort_by(&:happened_at)
      .each { |event| notes << event.message }
    notes
  end

  def mark_seen!
    update_column(:last_seen_at, Time.current)
  end

  def next_plot_cost
    PLOT_COSTS[plots.size]
  end

  def room_to_expand?
    plots.size < MAX_PLOTS && next_plot_cost.present?
  end

  def can_plant?(crop)
    coins >= crop.seed_cost && plots.any?(&:empty?)
  end

  def buy_plot
    with_lock do
      reload
      cost = next_plot_cost
      if cost.nil?
        errors.add(:base, "The acre can't grow any larger.")
      elsif coins < cost
        errors.add(:base, "A new bed costs #{cost} coins.")
      else
        update!(coins: coins - cost)
        plots.create!(position: plots.maximum(:position).to_i + 1)
        return true
      end
    end
    false
  end

  def weather_label
    WEATHERS.fetch(weather, WEATHERS["clear"])[0]
  end

  def weather_detail
    WEATHERS.fetch(weather, WEATHERS["clear"])[1]
  end

  private
    def strip_name
      self.name = name.to_s.strip
    end
end
