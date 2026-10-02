require "test_helper"

class HomesteadFlowTest < ActionDispatch::IntegrationTest
  test "planting and harvesting a radish" do
    get root_path
    assert_response :success
    assert_match "South Acre", response.body
    assert_select "article.bed", 4
    assert_match "Need 22", response.body

    homestead = Homestead.last
    plot = homestead.plots.order(:position).first

    post plant_plot_path(plot), params: { crop_key: "radish" }
    assert_redirected_to root_path(bed: plot.id)
    follow_redirect!
    assert_match "Planted radish on bed 1", response.body
    assert_equal 18, homestead.reload.coins

    post harvest_plot_path(plot)
    follow_redirect!
    assert_select ".flash--alert", /ready to pick/

    travel 25.seconds do
      get root_path
      assert_match "Harvest 5", response.body
      post harvest_plot_path(plot)
    end

    follow_redirect!
    assert_match "Harvested 5 coins", response.body
    assert_equal 23, homestead.reload.coins
    assert plot.reload.empty?
  end

  test "the shed plants the first empty bed" do
    get root_path
    homestead = Homestead.last

    post plant_next_plot_path, params: { crop_key: "lettuce" }
    plot = homestead.plots.order(:position).first
    assert_redirected_to root_path(bed: plot.id)
    follow_redirect!

    assert_equal "lettuce", plot.reload.crop_key
    assert_equal 16, homestead.reload.coins
  end

  test "each browser keeps its own acre" do
    get root_path
    patch homestead_path, params: { homestead: { name: "North Pasture" } }
    follow_redirect!
    assert_match "North Pasture", response.body

    other = open_session
    other.get root_path
    assert_match "South Acre", other.response.body
    assert_no_match "North Pasture", other.response.body
  end

  test "a bed from another acre cannot be planted" do
    get root_path
    plot = Homestead.last.plots.first

    other = open_session
    other.get root_path
    other.post plant_plot_path(plot), params: { crop_key: "radish" }
    other.assert_response :not_found
    assert plot.reload.empty?
  end

  test "a too-short name is refused" do
    get root_path
    patch homestead_path, params: { homestead: { name: "A" } }
    follow_redirect!
    assert_match "too short", response.body
  end
end
