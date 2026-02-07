class Video < ApplicationRecord
  belongs_to :user

  has_one_attached :original_video
  has_one_attached :stabilized_video

  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :original_filename, presence: true
  validate :original_video_presence
  validate :acceptable_video

  MAX_FILE_SIZE = 500.megabytes
  ALLOWED_CONTENT_TYPES = %w[
    video/mp4 video/quicktime video/x-msvideo video/webm video/x-matroska
    video/mpeg video/mp2t video/x-ms-wmv video/3gpp video/x-flv
  ].freeze

  private

  def original_video_presence
    unless original_video.attached?
      errors.add(:original_video, :blank)
    end
  end

  def acceptable_video
    return unless original_video.attached?

    if original_video.blob.byte_size > MAX_FILE_SIZE
      errors.add(:original_video, :file_too_large, max_size: '500MB')
    end

    unless ALLOWED_CONTENT_TYPES.include?(original_video.blob.content_type)
      errors.add(:original_video, :invalid_content_type)
    end
  end
end
