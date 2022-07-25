class HomeController < ApplicationController

  def prehrajto
    require "nokogiri"
    require "httparty"

    if params[:search_url] && params[:search_url].length > 0

      @divs = Array.new
      params[:search_url] = params[:search_url][8..-1]
      url = "https://prehrajto.cz/hledej/#{CGI.escape(params[:search_url].to_s)}"
      unparsed_page = HTTParty.get(url)

      unless unparsed_page.body.nil?

        parsed_page = Nokogiri::HTML(unparsed_page)
        result_divs = parsed_page.css("section").css("div.column")

        for r in result_divs do

          div = {
            href: r.css("a")[0].attributes["href"].value.strip,
            image_src: r.css("img")[0].attributes["src"].value.strip,
            duration: r.css("strong.video-item-info-time").text.strip,
            size: r.css("strong.video-item-info-size").text.strip,
            title: r.css("h2.video-item-title").text.strip
          }

          @divs << div
        end
      end
    end

    if params[:movie_url] && params[:movie_url].length > 0

      url = "https://prehrajto.cz/#{params[:movie_url]}"
      unparsed_page = HTTParty.get(url)

      puts "URL = #{url}"

      unless unparsed_page.body.nil?
        parsed_page = Nokogiri::HTML(unparsed_page)
        storage_substring = parsed_page.to_s[parsed_page.to_s.index('var sources')..parsed_page.to_s.index('var tracks')]
        @video_src = storage_substring[/#{"\""}(.*?)#{"\""}/m, 1].to_s
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