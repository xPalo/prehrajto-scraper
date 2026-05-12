module ApplicationHelper
  def current_class?(paths, *_)
    Array.wrap(paths).include?(request.path) ? "active" : ""
  end
end
