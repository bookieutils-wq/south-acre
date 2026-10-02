require "test_helper"

class HomesteadTest < ActiveSupport::TestCase
  test "a new acre starts with four beds and a stake" do
    homestead = Homestead.start!

    assert_equal 4, homestead.plots.count
    assert_equal 20, homestead.coins
    assert_equal "You staked a claim on a quiet acre.", homestead.world_events.first.message
  end

  test "rain hurries a crop that is still growing" do
    travel_to Time.zone.parse("2026-10-02 12:00:00") do
      homestead = Homestead.start!
      homestead.update!(coins: 50, weather: "rain", weather_until: 3.hours.from_now)
      plot = homestead.plots.first
      assert plot.plant("wheat")
      homestead.update!(last_ticked_at: Time.current)

      homestead.advance_world!(now: 2.minutes.from_now, rng: SequenceRandom.new(floats: [ 0.9, 0.9 ]))

      assert_equal 60, plot.reload.bonus_seconds
    end
  end

  test "a dry spell does not unripen a finished crop" do
    homestead = nil
    plot = nil
    later = nil

    travel_to Time.zone.parse("2026-10-02 12:00:00") do
      homestead = Homestead.start!
      homestead.update!(coins: 50, weather: "dry", weather_until: 3.hours.from_now)
      plot = homestead.plots.first
      plot.plant("radish")
      homestead.update!(last_ticked_at: Time.current)
      later = 2.minutes.from_now
    end

    travel_to later do
      homestead.advance_world!(now: later, rng: SequenceRandom.new(floats: [ 0.9, 0.9 ]))
      plot.reload
      assert plot.ready?
      assert_equal 0, plot.bonus_seconds
    end
  end

  test "crows spoil a crop left ripe" do
    travel_to Time.zone.parse("2026-10-02 12:00:00") do
      homestead = Homestead.start!
      homestead.update!(coins: 50, weather_until: 3.hours.from_now)
      plot = homestead.plots.first
      plot.plant("radish")
      homestead.update!(last_ticked_at: Time.current)

      changed = homestead.advance_world!(
        now: 2.minutes.from_now,
        rng: SequenceRandom.new(floats: [ 0.9, 0.04 ], ints: [ 0 ])
      )

      assert changed
      assert plot.reload.spoiled?
      assert_not plot.ready?
    end
  end

  test "a neighbor gift is recorded once" do
    homestead = Homestead.start!
    homestead.update!(weather_until: 3.hours.from_now, last_ticked_at: Time.current)
    before = homestead.coins

    assert homestead.advance_world!(now: 1.minute.from_now, rng: SequenceRandom.new(floats: [ 0.0 ], ints: [ 1 ]))
    assert_equal before + 3, homestead.reload.coins
    assert homestead.world_events.exists?(kind: "gift")

    assert_not homestead.advance_world!(rng: SequenceRandom.new(floats: [ 0.0 ], ints: [ 0 ]))
    assert_equal before + 3, homestead.reload.coins
  end

  test "a long absence is caught up without replaying every minute forever" do
    homestead = Homestead.start!
    homestead.update!(last_ticked_at: 40.days.ago)

    assert_nothing_raised do
      homestead.advance_world!(rng: Random.new(1))
    end
    assert_in_delta Time.current, homestead.reload.last_ticked_at, 2.seconds
  end

  test "arrival notes mention crops that finished after you left" do
    travel_to Time.zone.parse("2026-10-02 15:00:00") do
      homestead = Homestead.start!
      homestead.update!(coins: 30)
      homestead.plots.first.plant("radish")
      homestead.update_column(:last_seen_at, Time.current)

      travel 3.minutes

      assert_includes homestead.arrival_notes, "1 crop finished growing."
    end
  end

  test "buying a bed spends coins and adds a plot" do
    homestead = Homestead.start!
    homestead.update!(coins: 26)

    assert homestead.buy_plot
    assert_equal 5, homestead.plots.count
    assert_equal 0, homestead.reload.coins
  end

  test "a bed is refused when coins are short" do
    homestead = Homestead.start!

    assert_not homestead.buy_plot
    assert_equal 4, homestead.plots.count
    assert_match "26 coins", homestead.errors.full_messages.to_sentence
  end
end
