module FarmSession
  extend ActiveSupport::Concern

  private
    def current_homestead
      @current_homestead ||= find_homestead || start_homestead
    end

    def find_homestead
      return if session[:homestead_id].blank?

      Homestead.find_by(id: session[:homestead_id])
    end

    def start_homestead
      homestead = Homestead.start!
      session[:homestead_id] = homestead.id
      homestead
    end

    def crop_key_param
      key = params[:crop_key]
      key.is_a?(String) ? key : ""
    end
end
