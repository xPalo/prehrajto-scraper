class HomeController < ApplicationController

  def prehrajto
    require "uri"
    require "net/http"
    require "openssl"
    require "nokogiri"
    require "httparty"

    if params[:search_url] && params[:search_url].length > 0

      @divs = Array.new
      params[:search_url] = params[:search_url][8..-1]

      url = URI("https://prehrajto.cz/hledej/#{CGI.escape(params[:search_url].to_s)}")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(url)
      response = http.request(request)

      unless response.body.nil?

        parsed_page = Nokogiri::HTML(response.body)
        result_divs = parsed_page.css("section").css("div.column")

        # @check = response.body.to_s

        result_divs.each { |r|
          div = {
            "href" => r.css("a")[0].attributes["href"].value.strip.to_s,
            "image_src" => r.css("img")[0].attributes["src"].value.strip.to_s,
            "duration" => r.css("strong.video-item-info-time").text.strip.to_s,
            "size" => r.css("strong.video-item-info-size").text.strip.to_s,
            "title" => r.css("h2.video-item-title").text.strip.to_s
          }
          @divs << div
        }
      end
    end

    # if params[:search_url] && params[:search_url].length > 0
    #
    #   @divs = Array.new
    #   params[:search_url] = params[:search_url][8..-1]
    #   url = "https://prehrajto.cz/hledej/#{CGI.escape(params[:search_url].to_s)}"
    #   unparsed_page = HTTParty.get(url)
    #
    #   unless unparsed_page.body.nil?
    #
    #     parsed_page = Nokogiri::HTML(unparsed_page.gsub("\u0011", ''))
    #     result_divs = parsed_page.css("section").css("div.column")
    #
    #     @check = unparsed_page.body.to_s
    #
    #     result_divs.each { |r|
    #       div = {
    #         "href" => r.css("a")[0].attributes["href"].value.strip.to_s,
    #         "image_src" => r.css("img")[0].attributes["src"].value.strip.to_s,
    #         "duration" => r.css("strong.video-item-info-time").text.strip.to_s,
    #         "size" => r.css("strong.video-item-info-size").text.strip.to_s,
    #         "title" => r.css("h2.video-item-title").text.strip.to_s
    #       }
    #       @divs << div
    #     }
    #   end
    # end

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