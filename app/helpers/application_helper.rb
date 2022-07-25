module ApplicationHelper
  def current_class?(test_path, color="")
    return "active #{color}" if request.path == test_path
    " "
  end
end
