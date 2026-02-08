class VideosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_video, only: [:show, :destroy, :download]
  before_action :authorize_user, only: [:show, :destroy, :download]

  def index
    @videos = current_user.videos.order(created_at: :desc)
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: video_status_json(@video) }
    end
  end

  def new
    @video = Video.new
  end

  def create
    uploaded_file = params.dig(:video, :original_video)

    @video = Video.new(video_params)
    @video.user = current_user
    @video.original_filename = uploaded_file.try(:original_filename) || 'unknown'
    @video.file_size = uploaded_file.try(:size)

    if @video.save
      VideoStabilizeJob.perform_later(@video.id)
      redirect_to video_url(@video), notice: t(:'video.created')
    else
      Rails.logger.error("Video create failed: #{@video.errors.full_messages.join(', ')}")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @video.original_video.purge if @video.original_video.attached?
    @video.stabilized_video.purge if @video.stabilized_video.attached?
    @video.destroy

    respond_to do |format|
      format.html { redirect_to videos_url, notice: t(:'video.deleted') }
      format.json { head :no_content }
    end
  end

  def download
    if @video.completed? && @video.stabilized_video.attached?
      file_path = ActiveStorage::Blob.service.path_for(@video.stabilized_video.key)
      file_mtime = File.mtime(file_path)
      response.headers['Last-Modified'] = file_mtime.httpdate

      send_file file_path,
                filename: @video.stabilized_video.filename.to_s,
                type: @video.stabilized_video.content_type,
                disposition: 'attachment'
    else
      redirect_back(fallback_location: video_path(@video), alert: t(:'video.not_ready'))
    end
  end

  private

  def set_video
    @video = Video.find(params[:id])
  end

  def authorize_user
    redirect_back(fallback_location: root_path) unless current_user.id == @video.user_id || current_user.is_admin?
  end

  def video_params
    params.require(:video).permit(:original_video)
  end

  def video_status_json(video)
    {
      id: video.id,
      status: video.status,
      error_message: video.error_message,
      original_filename: video.original_filename,
      file_size: video.file_size,
      duration: video.duration,
      download_url: video.completed? && video.stabilized_video.attached? ? download_video_path(video) : nil
    }
  end
end
