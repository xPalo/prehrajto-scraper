module VideosHelper
  def video_status_badge_class(status)
    case status.to_s
    when 'pending'    then 'badge-mute'
    when 'processing' then 'badge-warn'
    when 'completed'  then 'badge-ok'
    when 'failed'     then 'badge-danger'
    else 'badge-mute'
    end
  end
end
