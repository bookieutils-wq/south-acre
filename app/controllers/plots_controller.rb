class PlotsController < ApplicationController
  include FarmSession

  before_action :set_plot, only: %i[plant harvest clear]

  def plant_next
    plot = current_homestead.plots.find(&:empty?)
    unless plot
      redirect_to root_path, alert: "Every bed is already planted.", status: :see_other
      return
    end

    @plot = plot
    plant
  end

  def plant
    crop = @plot.plant(crop_key_param)
    if crop
      redirect_to root_path(bed: @plot.id), notice: "Planted #{crop.name.downcase} on bed #{@plot.position + 1}.", status: :see_other
    else
      redirect_to root_path(bed: @plot.id), alert: @plot.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def harvest
    value = @plot.harvest
    if value
      redirect_to root_path(bed: @plot.id), notice: "Harvested #{value} coins.", status: :see_other
    else
      redirect_to root_path(bed: @plot.id), alert: @plot.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def clear
    if @plot.clear_bed
      redirect_to root_path(bed: @plot.id), notice: "You cleared the spoiled bed.", status: :see_other
    else
      redirect_to root_path(bed: @plot.id), alert: @plot.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def buy
    if current_homestead.buy_plot
      bed = current_homestead.plots.order(:position).last
      redirect_to root_path(bed: bed.id), notice: "A new bed is cleared and waiting.", status: :see_other
    else
      redirect_to root_path, alert: current_homestead.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_plot
      @plot = current_homestead.plots.find(params[:id])
    end
end
