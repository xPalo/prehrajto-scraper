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

      metadata = extract_metadata(input_path)
      video.update(duration: metadata[:duration]) if metadata[:duration]

      unless run_ffmpeg_pass1(input_path, transform_path)
        video.update(status: :failed, error_message: 'FFmpeg pass 1 (detect) failed')
        return
      end

      unless run_ffmpeg_pass2(input_path, transform_path, output_path, metadata[:creation_time])
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

  def extract_metadata(input_path)
    duration_out = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{input_path}" 2>&1`
    duration = duration_out.strip.to_f if duration_out.strip.match?(/\A[\d.]+\z/)

    creation_out = `ffprobe -v error -show_entries format_tags=creation_time -of default=noprint_wrappers=1:nokey=1 "#{input_path}" 2>&1`
    creation_time = creation_out.strip.presence

    { duration: duration, creation_time: creation_time }
  end

  def run_ffmpeg_pass1(input_path, transform_path)
    system(
      'ffmpeg', '-y', '-i', input_path,
      '-vf', "vidstabdetect=shakiness=8:accuracy=9:result=#{transform_path}",
      '-f', 'null', '-'
    )
  end

  def run_ffmpeg_pass2(input_path, transform_path, output_path, creation_time)
    cmd = [
      'ffmpeg', '-y', '-i', input_path,
      '-vf', "vidstabtransform=input=#{transform_path}:smoothing=20:crop=black:zoom=1",
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '18',
      '-c:a', 'copy',
      '-map_metadata', '0',
      '-movflags', '+use_metadata_tags+faststart'
    ]

    if creation_time
      cmd.push('-metadata', "creation_time=#{creation_time}")
    end

    cmd.push(output_path)
    system(*cmd)
  end

  def sanitize_filename(filename)
    filename.gsub(/[^0-9A-Za-z.\-_]/, '_')
  end
end
