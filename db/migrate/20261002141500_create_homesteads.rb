class CreateHomesteads < ActiveRecord::Migration[8.1]
  def change
    create_table :homesteads do |t|
      t.string :name, null: false, default: "South Acre"
      t.integer :coins, null: false, default: 20
      t.string :weather, null: false, default: "clear"
      t.datetime :weather_until
      t.datetime :last_ticked_at
      t.datetime :last_seen_at

      t.timestamps
    end

    create_table :plots do |t|
      t.references :homestead, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :crop_key
      t.datetime :planted_at
      t.integer :bonus_seconds, null: false, default: 0
      t.boolean :spoiled, null: false, default: false

      t.timestamps
    end
    add_index :plots, [ :homestead_id, :position ], unique: true

    create_table :world_events do |t|
      t.references :homestead, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :message, null: false
      t.datetime :happened_at, null: false

      t.timestamps
    end
    add_index :world_events, [ :homestead_id, :happened_at ]
  end
end
