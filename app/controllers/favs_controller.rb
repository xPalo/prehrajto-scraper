class FavsController < ApplicationController
  require "uri"
  require "net/http"

  before_action :set_fav, only: [:show, :destroy]

  def index
    if user_signed_in?
      @favs = current_user.favs.order(:title)
    else
      redirect_to new_user_session_url, notice: t(:'have_to_be_signed_in')
    end
  end

  def show
  end

  def new
    @fav = Fav.new
  end

  def create
    @fav = Fav.new(fav_params)

    respond_to do |format|
      if @fav.save
        format.html { redirect_to fav_url(@fav), notice: t(:'fav.created') }
        format.json { render :show, status: :created, location: @fav }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @fav.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @fav.destroy

    respond_to do |format|
      format.html { redirect_to favs_url, notice: t(:'fav.deleted') }
      format.json { head :no_content }
    end
  end

  private

  def set_fav
    @fav = Fav.find(params[:id])
  end

  def fav_params
    params.require(:fav).permit(:title, :duration, :size, :user_id, :link, :image_src)
  end
end