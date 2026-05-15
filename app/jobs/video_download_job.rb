class VideoDownloadJob < ApplicationJob
  queue_as :video_processing

  def perform(video_id, url)
    video = Video.find_by(id: video_id)
    return if video.nil? || !video.pending?

    video.processing!

    Dir.mktmpdir('video_download') do |tmpdir|
      output_path = File.join(tmpdir, 'video.mp4')

      ok = system(
        'yt-dlp',
        '--no-playlist',
        '--no-progress',
        '--no-warnings',
        '--max-filesize', '500M',
        '--format', 'bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/b',
        '--merge-output-format', 'mp4',
        '--write-info-json',
        '--no-write-thumbnail',
        '--no-write-subs',
        '--restrict-filenames',
        '--output', output_path,
        url
      )

      unless ok && File.exist?(output_path)
        video.update(status: :failed, error_message: 'yt-dlp download failed')
        return
      end

      info_path = Dir.glob(File.join(tmpdir, '*.info.json')).first
      info = info_path && File.exist?(info_path) ? (JSON.parse(File.read(info_path)) rescue {}) : {}
      title = info['title'].presence || File.basename(url)
      upload_date = parse_yt_dlp_date(info['upload_date'])
      duration = info['duration']

      filename = ActiveStorage::Filename.new("#{title}.mp4").sanitized
      video.original_video.attach(
        io: File.open(output_path),
        filename: filename,
        content_type: 'video/mp4'
      )

      video.update(
        original_filename: filename,
        recorded_at: upload_date,
        duration: duration,
        file_size: File.size(output_path)
      )
      video.completed!
    end
  rescue StandardError => e
    video&.update(status: :failed, error_message: e.message.truncate(500)) if video&.persisted?
    Rails.logger.error("VideoDownloadJob failed for video #{video_id}: #{e.message}")
  end

  private

  def parse_yt_dlp_date(yyyymmdd)
    return nil if yyyymmdd.blank?
    Date.strptime(yyyymmdd.to_s, '%Y%m%d') rescue nil
  end
end
