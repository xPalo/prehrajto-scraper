module ApplicationHelper
  def current_class?(path, color="")
    return "active #{color}" if request.path == path
    " "
  end
end
