class HomeController < ApplicationController
  SIMILAR_LIMIT = 10

  def prehrajto
    if params[:search_url] && params[:search_url].length > 0
      params[:search_url] = params[:search_url][8..-1]
      @divs = PrehrajtoSearcher.search(params[:search_url])

      order_divs_by(params[:order]) if params[:order].present?
      @no_results = true if @divs.blank?
    end

    if params[:movie_url] && params[:movie_url].length > 0
      url = "https://prehrajto.cz/#{params[:movie_url]}"
      unparsed_page = HTTParty.get(url)

      if unparsed_page.body.present?
        parsed_page = Nokogiri::HTML(unparsed_page.force_encoding('UTF-8'))
        storage_substring = parsed_page.to_s[parsed_page.to_s.index('var sources')..parsed_page.to_s.index('var tracks')]
        @video_src = storage_substring[/#{"\""}(.*?)#{"\""}/m, 1].to_s.strip
      end
    end
  end

  def similar
    query = params[:q].presence || PrehrajtoSearcher.normalize_title(params[:title])
    results = PrehrajtoSearcher.search(query)
    exclude = params[:exclude].to_s
    results = results.reject { |r| r[:href] == exclude } if exclude.present?
    @similar = results.first(SIMILAR_LIMIT)

    render layout: false
  end

  def change_locale
    lang = params[:locale].to_s.strip.to_sym
    lang = I18n.default_locale unless I18n.available_locales.include?(lang)
    cookies[:lang] = lang

    redirect_to(request.referer || root_url, allow_other_host: true)
  end

  private

  def order_divs_by(order_attribute)
    case order_attribute
      when "title_asc"
        @divs.sort_by! { |div| div[:title].downcase }
      when "title_desc"
        @divs.sort_by! { |div| div[:title].downcase }.reverse!

      when "size_asc"
        @divs = @divs.sort_by { |div| div[:size_numeric] }
      when "size_desc"
        @divs = @divs.sort_by { |div| -div[:size_numeric] }

      when "duration_asc"
        @divs = @divs.sort_by { |div| div[:duration_numeric] }
      when "duration_desc"
        @divs = @divs.sort_by { |div| -div[:duration_numeric] }
    else
      flash[:alert] = t(:'order.invalid_value')
    end
  end
end
