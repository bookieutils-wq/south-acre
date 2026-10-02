class Crop
  attr_reader :key, :name, :seconds, :seed_cost, :harvest_value, :summary, :hue

  def initialize(key:, name:, seconds:, seed_cost:, harvest_value:, summary:, hue:)
    @key = key
    @name = name
    @seconds = seconds
    @seed_cost = seed_cost
    @harvest_value = harvest_value
    @summary = summary
    @hue = hue
  end

  ALL = [
    new(key: "radish", name: "Radish", seconds: 20, seed_cost: 2, harvest_value: 5, hue: "#c44536",
      summary: "The fastest thing in the shed."),
    new(key: "lettuce", name: "Lettuce", seconds: 75, seed_cost: 4, harvest_value: 10, hue: "#6a9a3e",
      summary: "A loose head and a quick return."),
    new(key: "wheat", name: "Wheat", seconds: 180, seed_cost: 7, harvest_value: 18, hue: "#d7a441",
      summary: "A small stand of grain."),
    new(key: "tomato", name: "Tomato", seconds: 8.minutes.to_i, seed_cost: 12, harvest_value: 32, hue: "#d4533a",
      summary: "Slow vines, better profit."),
    new(key: "pumpkin", name: "Pumpkin", seconds: 20.minutes.to_i, seed_cost: 22, harvest_value: 64, hue: "#e08a2a",
      summary: "Heavy fruit if you can wait."),
    new(key: "apple", name: "Apple", seconds: 60.minutes.to_i, seed_cost: 36, harvest_value: 120, hue: "#b4333a",
      summary: "A young tree. Come back later.")
  ].freeze

  def self.all
    ALL
  end

  def self.find(key)
    ALL.find { |crop| crop.key == key.to_s }
  end

  def profit
    harvest_value - seed_cost
  end
end
