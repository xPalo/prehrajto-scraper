require "uri"
require "net/http"

class WatchdogsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_watchdog, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user, only: [:show, :edit, :update, :destroy]

  def index
    @watchdogs = current_user.watchdogs.order(is_active: :desc, id: :asc)
  end

  def show
  end

  def new
    @watchdog = Watchdog.new(is_active: true)
  end

  def edit
  end

  def create
    @watchdog = Watchdog.new(watchdog_params)

    respond_to do |format|
      if @watchdog.save
        format.html { redirect_to watchdogs_url, notice: t(:'watchdog.created') }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @watchdog.update(watchdog_params)
        format.html { redirect_to watchdogs_url, notice: t(:'watchdog.updated') }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @watchdog.destroy

    respond_to do |format|
      format.html { redirect_to watchdogs_url, notice: t(:'watchdog.deleted') }
    end
  end

  private

  def set_watchdog
    @watchdog = Watchdog.find(params[:id])
  end

  def authorize_user
    redirect_back(fallback_location: root_path) unless current_user.id == @watchdog.user_id || current_user.is_admin?
  end

  def watchdog_params
    params.require(:watchdog).permit(:from_airport, :to_airport, :to_country, :max_price, :date_watch_from, :date_watch_to,
                                     :departure_time_from, :departure_time_to, :user_id, :is_active)
  end
end