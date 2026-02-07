module VideosHelper
  def video_status_badge_class(status)
    case status.to_s
    when 'pending' then 'bg-secondary'
    when 'processing' then 'bg-warning text-dark'
    when 'completed' then 'bg-success'
    when 'failed' then 'bg-danger'
    else 'bg-secondary'
    end
  end
end
