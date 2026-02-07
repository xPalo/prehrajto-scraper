class VideoStabilizeJob < ApplicationJob
  queue_as :video_processing

  def perform(video_id)
    video = Video.find_by(id: video_id)
    return if video.nil? || !video.pending?

    video.processing!

    Dir.mktmpdir('video_stabilize') do |tmpdir|
      input_path = File.join(tmpdir, sanitize_filename(video.original_filename))
      transform_path = File.join(tmpdir, 'transforms.trf')
      output_filename = "stabilized_#{File.basename(video.original_filename, '.*')}.mp4"
      output_path = File.join(tmpdir, output_filename)

      video.original_video.open do |tempfile|
        FileUtils.cp(tempfile.path, input_path)
      end

      duration = extract_duration(input_path)
      video.update(duration: duration) if duration

      unless run_ffmpeg_pass1(input_path, transform_path)
        video.update(status: :failed, error_message: 'FFmpeg pass 1 (detect) failed')
        return
      end

      unless run_ffmpeg_pass2(input_path, transform_path, output_path)
        video.update(status: :failed, error_message: 'FFmpeg pass 2 (transform) failed')
        return
      end

      video.stabilized_video.attach(
        io: File.open(output_path),
        filename: output_filename,
        content_type: 'video/mp4'
      )

      video.completed!
    end
  rescue StandardError => e
    video&.update(status: :failed, error_message: e.message.truncate(500)) if video&.persisted?
    Rails.logger.error("VideoStabilizeJob failed for video #{video_id}: #{e.message}")
  end

  private

  def extract_duration(input_path)
    output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{input_path}" 2>&1`
    output.strip.to_f if output.strip.match?(/\A[\d.]+\z/)
  end

  def run_ffmpeg_pass1(input_path, transform_path)
    system(
      'ffmpeg', '-y', '-i', input_path,
      '-vf', "vidstabdetect=shakiness=6:accuracy=5:result=#{transform_path}",
      '-f', 'null', '-'
    )
  end

  def run_ffmpeg_pass2(input_path, transform_path, output_path)
    system(
      'ffmpeg', '-y', '-i', input_path,
      '-vf', "vidstabtransform=input=#{transform_path}:smoothing=10:crop=black:zoom=1",
      '-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '23',
      '-c:a', 'copy',
      output_path
    )
  end

  def sanitize_filename(filename)
    filename.gsub(/[^0-9A-Za-z.\-_]/, '_')
  end
end
