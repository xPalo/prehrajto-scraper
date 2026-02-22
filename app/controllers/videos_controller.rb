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
  end

  def create
    uploaded_files = Array(params[:original_videos]).reject(&:blank?)
    recorded_ats = JSON.parse(params[:recorded_ats] || '[]') rescue []

    if uploaded_files.empty?
      redirect_to new_video_path, alert: t(:'video.select_file')
      return
    end

    videos = []
    errors = []

    uploaded_files.each_with_index do |file, index|
      video = Video.new
      video.user = current_user
      video.original_video.attach(file)
      video.original_filename = file.original_filename
      video.file_size = file.size
      video.recorded_at = recorded_ats[index]

      if video.save
        VideoStabilizeJob.perform_later(video.id)
        videos << video
      else
        errors << "#{file.original_filename}: #{video.errors.full_messages.join(', ')}"
        Rails.logger.error("Video create failed for #{file.original_filename}: #{video.errors.full_messages.join(', ')}")
      end
    end

    if videos.any?
      notice = videos.size == 1 ? t(:'video.created') : t(:'video.created_multiple', count: videos.size)

      if errors.any?
        redirect_to videos_url, notice: notice, alert: errors.join('; ')
      elsif videos.size == 1
        redirect_to video_url(videos.first), notice: notice
      else
        redirect_to videos_url, notice: notice
      end
    else
      redirect_to new_video_path, alert: errors.join('; ')
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
      original_date = @video.recorded_at || File.mtime(file_path)
      response.headers['Last-Modified'] = original_date.httpdate

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
