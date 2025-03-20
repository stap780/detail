# This service class is responsible for parsing URLs.
class Idc::ParsUrl < ApplicationService

  def initialize(url)
    @url = url
    @idc = Idc.find_by_url(@url)
    @idc.update!(status: 'process') if @idc.present?
  end

  def call
    parse_url
  end

  private

  def parse_url
    Rails.logger = Logger.new(Rails.root.join('log', 'idc_pars.log'))
    Rails.logger.info("Starting to parse URL: #{@url}")
    RestClient.proxy = get_proxy
    RestClient.get(@url, open_timeout: 240 ) { |response, request, result, &block|
      case response.code
      when 200
        Rails.logger.info("Successfully fetched URL: #{@url}")
        pr_doc = Nokogiri::HTML(response)
        data = collect_data(pr_doc)
        # Rails.logger.debug("Collected data: #{data}")
        @idc.present? ? @idc.update!(data.except!(:sku)) : Idc.create!(data)
      when 404
        Rails.logger.error("Error 404: URL not found - #{@url}")
        @idc.update!(status: 'error') if @idc.present?
      when 429
        Rails.logger.error("Error 429: Too many requests for URL: #{@url}")
        Rails.logger.debug("Request details: #{request}")
        Rails.logger.debug("Result details: #{result}")
        @idc.update!(status: 'error') if @idc.present?
      when 503
        Rails.logger.error("Error 503: Service unavailable for URL: #{@url}")
        @idc.update!(status: 'error') if @idc.present?
        break
      else
        Rails.logger.error("Error in else for URL: #{@url}")
        @idc.update!(status: 'error') if @idc.present?
        response.return!(&block)
      end
    }
  end

  def collect_data(pr_doc)
    title = pr_doc.css('h1').text.squish
    desc = pr_doc.css('.catalog-element-description__text').text.squish
    cat = clear_cat(pr_doc)
    sku = clear_sku(pr_doc)
    charact = clear_charact(pr_doc)
    charact_gab = clear_charact_gab(pr_doc)
    oldprice = clear_oldprice(pr_doc)
    price = clear_price(pr_doc)
    quantity = clear_quantity(pr_doc)
    image = clear_image(pr_doc)

    {
      sku: sku,
      title: title,
      desc: desc,
      cat: cat,
      charact: charact,
      charact_gab: charact_gab,
      oldprice: oldprice,
      price: price,
      quantity: quantity,
      image: image,
      url: @url,
      status: 'finish'
    }
  end

  def clear_cat(pr_doc)
    exclude_cat = %w[Каталог Категория]
    cat_array = pr_doc.css('.breadcrumbs__element--title').children.map(&:text).reject { |b| exclude_cat.include?(b) }
    cat_array.join('---')
  end

  def clear_sku(pr_doc)
    sku_array = []
    sku_keys = %w[Артикул Артикул:]
    pr_doc.css('.element-popups__content .first .content-item__element').each do |item|
      key = item.inner_html.squish.split('<span>').first.strip
      value = item.text.remove(key.to_s).squish
      sku_array.push(value) if sku_keys.include?(key)
    end
    sku_array.join().squish
  end

  def clear_charact_gab(pr_doc)
    charact_gab_array = []
    gab_keys = %w[Габариты Габариты:]
    pr_doc.css('.element-popups__content .first .content-item__element').each do |item|
      key = item.inner_html.squish.split('<span>').first.strip
      value = item.text.remove(key.to_s).squish
      charact_gab_array.push(value) if gab_keys.include?(key)
    end
    charact_gab_array.join().gsub('cm', '').gsub('см', '').gsub('h.','').gsub(' ', '').gsub('W.', '').gsub('maxW.', '').gsub('H.', '').gsub('max','').gsub('|','x')
  end

  def clear_charact(pr_doc)
    characts_array = []
    exclude_keys = %w[Артикул Габариты Артикул: Габариты:]
    pr_doc.css('.element-popups__content .first .content-item__element').each do |item|
      key = item.inner_html.squish.split('<span>').first.strip
      value = item.text.remove(key.to_s).squish
      clear_key = key.include?(':') ? key : "#{key}:"
      characts_array.push("#{clear_key} #{value}") unless exclude_keys.include?(key)
    end
    characts_array.join('---')
  end

  def clear_oldprice(pr_doc)
    node = pr_doc.css('.element-info__default-price .discount')
    return 0 unless node.present?

    node.text.squish.gsub(' ', '').gsub('руб.', '').gsub('.0', '')
  end

  def clear_price(pr_doc)
    node = pr_doc.css('.element-info__default-price .price')
    return 0 unless node.present?

    node.text.squish.gsub(' ', '').gsub('руб.', '').gsub('.0', '')
  end

  def clear_quantity(pr_doc)
    node = pr_doc.css('.element-info__availability-have')
    return 0 unless node.present?

    node.text.squish.split(':').last.strip.gsub(' шт.', '')
  end

  def clear_image(pr_doc)
    picts = []
    main_node = pr_doc.css('.element-slider__image')
    thumb_node = pr_doc.css('.element-slider__nav-image img')
    return '' unless main_node.size.positive? || thumb_node.size.positive?

    pict_main = main_node.size.positive? ? main_node[0]['src'] : nil
    picts.push(pict_main)

    if thumb_node.size.positive?
      thumb_node.each do |p|
        picts.push(p['src']) unless p['src'].include?('3dbutton')
      end
    end
    picts.reject(&:blank?).map { |a| "https://idcollection.ru#{ a.gsub('resize_cache','iblock').gsub('197_140_1/', '') }" }.uniq.join(' ')
  end

  def get_proxy
    index = @idc.present? ? get_index : random_index

    proxy = Webshare.new
    link = proxy.proxy_by_index(index)
    puts "proxy link => #{link}"
    link
  end

  def get_index
    check = @idc.id.to_s.size > 1 ? @idc.id.to_s[-2..-1].to_i : @idc.id.to_i
    check.zero? ? random_index : check
  end

  def random_index
    rand(1..100)
  end

end