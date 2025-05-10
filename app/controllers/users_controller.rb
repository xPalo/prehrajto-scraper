class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user, only: [:index]

  def index
    @users = User.includes(:favs).page(params[:page])
  end

  private

  def authorize_user
    redirect_back(fallback_location: root_path) unless current_user.is_admin?
  end
end
