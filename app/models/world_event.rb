class WorldEvent < ApplicationRecord
  belongs_to :homestead, inverse_of: :world_events

  validates :kind, :message, :happened_at, presence: true
  validates :message, length: { maximum: 280 }
end
