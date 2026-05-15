class PrehrajtoSearcher
  CACHE_TTL = 1.hour

  NOISE_TOKENS = %w[
    1080p 720p 2160p 480p 4K UHD HDR
    BluRay BRRip BDRip WEB-DL WEBRip HDRip DVDRip HDTV CAM TS
    x264 x265 H264 H265 HEVC XviD DivX
    AAC AC3 DTS 5.1 7.1 DD5.1
    REPACK PROPER EXTENDED UNRATED LIMITED iNTERNAL MULTI
    CZ SK EN DABING TITULKY
  ].freeze

  def self.search(query)
    return [] if query.blank?

    Rails.cache.fetch("prehrajto_search:#{query}", expires_in: CACHE_TTL) do
      url = "https://prehrajto.cz/hledej/#{CGI.escape(query.to_s)}"
      unparsed_page = HTTParty.get(url)

      next [] if unparsed_page.body.blank?

      parsed_page = Nokogiri::HTML(unparsed_page.force_encoding('UTF-8'))
      result_divs = parsed_page.css('div.video__picture--container')

      result_divs.map do |r|
        size_str = r.css("div.video__tag--size").text.strip.to_s
        duration_str = r.css("div.video__tag--time").text.strip.to_s

        {
          href: r.css("a")[0].attributes["href"].value.strip.to_s,
          title: r.css("a")[0].attributes["title"].value.strip.to_s,
          image_src: r.css("img")[0].attributes["src"].value.strip.to_s,
          duration: duration_str,
          size: size_str,
          size_numeric: filesize_to_mb(size_str),
          duration_numeric: duration_to_seconds(duration_str)
        }
      end
    end
  end

  def self.normalize_title(raw)
    return "" if raw.blank?

    cleaned = raw.to_s.dup
    NOISE_TOKENS.each do |token|
      cleaned = cleaned.gsub(/(?<![A-Za-z0-9])#{Regexp.escape(token)}(?![A-Za-z0-9])/i, ' ')
    end
    cleaned = cleaned.tr('._', ' ')
    cleaned = cleaned.sub(/-[^-\s]+\s*$/, ' ')
    cleaned = cleaned.gsub(/\b(19|20)\d\d\b/, ' ')

    cleaned = cleaned.squeeze(' ').strip
    truncated = cleaned.split(/\s+/).first(5).join(' ')
    truncated.presence || raw.to_s.strip
  end

  def self.duration_to_seconds(duration_str)
    h, m, s = duration_str.split(':').map(&:to_i)
    h * 3600 + m * 60 + s
  end

  def self.filesize_to_mb(filesize_str)
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
