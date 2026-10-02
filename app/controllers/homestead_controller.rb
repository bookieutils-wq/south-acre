class HomesteadController < ApplicationController
  include FarmSession

  def show
    @homestead = current_homestead
    @homestead.advance_world!
    @plots = @homestead.plots
    @events = @homestead.world_events.limit(8)
    @arrival = turbo_frame_request? ? [] : @homestead.arrival_notes
    @homestead.mark_seen!
    WorldTicker.start
  end

  def update
    if current_homestead.update(homestead_params)
      redirect_to root_path, notice: "The acre has a new name.", status: :see_other
    else
      redirect_to root_path, alert: current_homestead.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def homestead_params
      params.require(:homestead).permit(:name)
    end
end
