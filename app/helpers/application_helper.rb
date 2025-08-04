module ApplicationHelper
  def current_class?(paths, color="")
    return "active #{color}" if Array.wrap(paths).include?(request.path)
    " "
  end
end
