require "uri"
require "net/http"

class FavsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_fav, only: [:show, :destroy]
  before_action :authorize_user, only: [:show, :destroy]

  def index
    @favs = current_user.favs.order(:title)
  end

  def show
  end

  def new
    if params[:movie_url] && params[:movie_url].length > 0
      url = "https://prehrajto.cz/#{params[:movie_url]}"
      unparsed_page = HTTParty.get(url)

      if unparsed_page.body.present?
        parsed_page = Nokogiri::HTML(unparsed_page.force_encoding('UTF-8'))
        storage_substring = parsed_page.to_s[parsed_page.to_s.index('var sources')..parsed_page.to_s.index('var tracks')]
        @video_src = storage_substring[/#{"\""}(.*?)#{"\""}/m, 1].to_s.strip
      end
    end

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

  def authorize_user
    redirect_back(fallback_location: root_path) unless current_user.id == @fav.user_id || current_user.is_admin?
  end

  def fav_params
    params.require(:fav).permit(:title, :duration, :size, :user_id, :link, :image_src)
  end
end