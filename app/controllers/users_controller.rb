class UsersController < ApplicationController
  before_action :set_user, only: [:show]
  before_action :authenticate_user!

  def index
    @users = User.where.not(id: current_user.id).page(params[:page])
  end

  def show
  end

  private

  def set_user
    @user = User.where(id: params[:id])
  end
end
