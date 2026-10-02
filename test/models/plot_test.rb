require "test_helper"

class PlotTest < ActiveSupport::TestCase
  setup do
    @homestead = Homestead.start!
    @plot = @homestead.plots.first
  end

  test "planting spends seed money and harvesting pays it back" do
    crop = @plot.plant("radish")

    assert_equal "radish", crop.key
    assert_equal 18, @homestead.reload.coins
    assert @plot.growing?

    travel 25.seconds do
      assert @plot.ready?
      assert_equal 5, @plot.harvest
    end

    assert @plot.reload.empty?
    assert_equal 23, @homestead.reload.coins
  end

  test "a crop cannot be picked early or planted twice" do
    @plot.plant("lettuce")

    assert_nil @plot.harvest
    assert_match "isn't ready", @plot.errors.full_messages.to_sentence
    assert_nil @plot.plant("radish")
    assert_match "already planted", @plot.errors.full_messages.to_sentence
  end

  test "unaffordable seed is refused" do
    @homestead.update!(coins: 1)

    assert_nil @plot.plant("wheat")
    assert_equal 1, @homestead.reload.coins
    assert @plot.empty?
  end

  test "a spoiled bed can be cleared" do
    @plot.update!(crop_key: "tomato", planted_at: 1.hour.ago, spoiled: true)

    assert @plot.clear_bed
    assert @plot.reload.empty?
  end
end
