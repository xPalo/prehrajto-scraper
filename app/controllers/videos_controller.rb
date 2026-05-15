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

  def from_url
  end

  def create_from_url
    url = params[:url].to_s.strip
    uri = URI.parse(url) rescue nil
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      redirect_to from_url_videos_path, alert: t(:'video.invalid_url') and return
    end

    video = current_user.videos.new(original_filename: t(:'video.placeholder_filename'))
    if video.save(validate: false)
      VideoDownloadJob.perform_later(video.id, url)
      redirect_to video_url(video), notice: t(:'video.url_enqueued')
    else
      redirect_to from_url_videos_path, alert: video.errors.full_messages.join(', ')
    end
  end

  def create
    uploaded_files = Array(params[:original_videos]).reject(&:blank?)
    recorded_ats = JSON.parse(params[:recorded_ats] || '[]') rescue []

    if uploaded_files.empty?
      respond_to do |format|
        format.html { redirect_to new_video_path, alert: t(:'video.select_file') }
        format.json { render json: { errors: [t(:'video.select_file')] }, status: :unprocessable_entity }
      end
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
      redirect_url = videos.size == 1 && errors.empty? ? video_url(videos.first) : videos_url

      respond_to do |format|
        format.html do
          if errors.any?
            redirect_to videos_url, notice: notice, alert: errors.join('; ')
          elsif videos.size == 1
            redirect_to video_url(videos.first), notice: notice
          else
            redirect_to videos_url, notice: notice
          end
        end
        format.json { render json: { redirect_url: redirect_url, notice: notice, errors: errors } }
      end
    else
      respond_to do |format|
        format.html { redirect_to new_video_path, alert: errors.join('; ') }
        format.json { render json: { errors: errors }, status: :unprocessable_entity }
      end
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
    attachment =
      if @video.stabilized_video.attached?
        @video.stabilized_video
      elsif @video.completed? && @video.original_video.attached?
        @video.original_video
      end

    unless attachment
      redirect_back(fallback_location: video_path(@video), alert: t(:'video.not_ready')) and return
    end

    file_path = ActiveStorage::Blob.service.path_for(attachment.key)
    original_date = @video.recorded_at || File.mtime(file_path)
    response.headers['Last-Modified'] = original_date.httpdate

    send_file file_path,
              filename: attachment.filename.to_s,
              type: attachment.content_type,
              disposition: 'attachment'
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
      download_url: (video.completed? && (video.stabilized_video.attached? || video.original_video.attached?)) ? download_video_path(video) : nil
    }
  end
end
