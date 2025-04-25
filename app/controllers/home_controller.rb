class HomeController < ApplicationController
  def prehrajto
    if params[:search_url] && params[:search_url].length > 0
      params[:search_url] = params[:search_url][8..-1]
      url = "https://prehrajto.cz/hledej/#{CGI.escape(params[:search_url].to_s)}"
      unparsed_page = HTTParty.get(url)

      if unparsed_page.body.present?
        parsed_page = Nokogiri::HTML(unparsed_page.force_encoding('UTF-8'))
        result_divs = parsed_page.css('div.video__picture--container')

        @divs = result_divs.map do |r|
          {
            href: r.css("a")[0].attributes["href"].value.strip.to_s,
            title: r.css("a")[0].attributes["title"].value.strip.to_s,
            image_src: r.css("img")[0].attributes["src"].value.strip.to_s,
            duration: r.css("div.video__tag--time").text.strip.to_s,
            size: r.css("div.video__tag--size").text.strip.to_s
          }
        end

        @no_results = true if @divs.blank?
      end
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

  def change_locale
    lang = params[:locale].to_s.strip.to_sym
    lang = I18n.default_locale unless I18n.available_locales.include?(lang)
    cookies[:lang] = lang
    redirect_to request.referer || root_url
  end
end
