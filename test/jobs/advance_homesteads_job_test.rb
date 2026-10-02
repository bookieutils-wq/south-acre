require "test_helper"

class AdvanceHomesteadsJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "ticks every acre and does not reschedule itself in test" do
    homestead = Homestead.start!
    homestead.update_columns(last_ticked_at: 5.minutes.ago)

    assert_no_enqueued_jobs only: AdvanceHomesteadsJob do
      AdvanceHomesteadsJob.perform_now
    end

    assert_in_delta Time.current, homestead.reload.last_ticked_at, 2.seconds
  end
end
