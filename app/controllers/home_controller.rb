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
            size: r.css("div.video__tag--size").text.strip.to_s,
            size_numeric: filesize_to_mb(r.css("div.video__tag--size").text.strip.to_s),
            duration_numeric: duration_to_seconds(r.css("div.video__tag--time").text.strip.to_s)
          }
        end

        order_divs_by(params[:order]) if params[:order].present?
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

  def duration_to_seconds(duration_str)
    h, m, s = duration_str.split(':').map(&:to_i)
    h * 3600 + m * 60 + s
  end

  def filesize_to_mb(filesize_str)
    number, unit = filesize_str.strip.upcase.split
    size = number.to_f

    case unit
      when "GB"
        (size * 1024).round
      when "MB"
        size.round
      when "KB"
        (size / 1024).ceil
      else
        raise ArgumentError, "Neznáma jednotka: #{unit}"
    end
  end
end
