# KareParsPage < ApplicationService
class KareParsPage < ApplicationService
  # require 'open-uri'
  # require 'faraday'

  attr_reader :link, :doc, :data

  def initialize(link)
    @link = link
    @doc = nil
    @data = {}
    @kare = Kare.find_by_url(@link)
    @kare.update(status: 'process') if @kare.present?
  end

  def call
    get_doc
    return unless check_product_page

    remove_double_info
    parse_doc
  end

  private

  def get_doc
    Rails.logger = Logger.new(Rails.root.join('log', 'kare_pars.log'))
    Rails.logger.info 'start get_doc'

    # conn = Faraday.new(url: @link,
    #                     ssl: { verify: false },
    #                     proxy: get_proxy
    #                     ) do |faraday|
    #     # Set the Authorization header with the Bearer token
    #     # faraday.request :authorization, 'Bearer', 'MySecretKey'
    # end
    # response = conn.get
    # Rails.logger.info "get_doc response => #{response}"
    # response.headers
    # Rails.logger.info "get_doc response.status => #{response.status}"
    # response.body
    # @doc = Nokogiri::HTML(response.body)
    # Rails.logger.info("Starting to parse URL: #{@link}")

    RestClient.proxy = get_proxy
    RestClient.get(@link, open_timeout: 240 ) { |response, request, result, &block|
      Rails.logger.info("Send request - #{request.inspect}")
      # Rails.logger.info("Get response headers - #{response.headers}")
      case response.code
      when 200
        Rails.logger.info("Successfully fetched URL: #{@link}")
        @doc = Nokogiri::HTML(response.body)
      when 301, 302, 307
        response.follow_redirection
      when 400
        Rails.logger.error("HTTP error for URL: #{@link} - #{response.code} - #{response}")
        @kare.update!(status: 'error') if @kare.present?
      when 404
        Rails.logger.error("HTTP error for URL: #{@link} - #{response.code} - #{response}")
        @kare.update!(status: 'error') if @kare.present?
      when 423
        Rails.logger.error("HTTP error for URL: #{@link} - #{response.code} - #{response}")
        @kare.update!(status: 'error') if @kare.present?
      when 429
        Rails.logger.error("HTTP error for URL: #{@link} - #{response.code} - #{response}")
        @kare.update!(status: 'error') if @kare.present?
      else
        Rails.logger.error("Error in else for URL: #{@link}")
        @kare.update!(status: 'error') if @kare.present?
        response.return!(&block)
      end
    }
  end

  def check_product_page
    return false if @doc.nil?

    puts 'start check_product_page'
    @doc.css('.rs-product__card').present? && @doc.css('.rs-product__card').inner_html.present?
  end

  def remove_double_info
    puts 'start remove_double_info'
    @doc.css('.modal').remove
  end

  def parse_doc
    puts 'start parse_doc'
    title = @doc.css('.rs-product__title h4').text
    if @doc.css('.rs-product__price_old').present?
      price = @doc.css('.rs-product__price_old').text.split('').reject(&:blank?).join.remove('₽')
    else
      price = @doc.css('.rs-product__price_actual').text.split('').reject(&:blank?).join.remove('₽')
    end

    desc = @doc.css('.tabs__body .rs-product__block').map { |line| line.css('.small-text').inner_html if line.css('h4').text.include?('Описание') }
    material = @doc.css('.rs-product__characteristics_item').map { |line| 'Материал:' + line.css('.small-text').text.gsub(':', '-').strip if line.css('h6').text.include?('Материал:') }.reject(&:blank?)
    sizes = @doc.css('.rs-product__characteristics_item ul li').map { |line| line.inner_html.remove(':').gsub('<span>', ':').remove('</span>').squish if line.inner_html && line.inner_html.respond_to?('squish') }
    charact = (sizes + material).join('---')
    extra = @doc.css('.tabs__body .rs-product__block').map { |line| line.css('.rs-product__links').inner_html if line.css('h4').text.include?('Инструкция') }
    full_desc = desc + extra

    quantity_euro = []
    quantity = []
    @doc.css('.stock-confirmed').each do |stock|
      value = stock.css('.quantity-info h6').text.split('').reject(&:blank?).join.remove('шт')
      quantity.push(value) if stock.css('.store-info h6').text.include?('России')
      quantity_euro.push(value) if stock.css('.store-info h6').text.include?('Мюнхене')
    end
    images = @doc.css('.rs-product__slide img').map { |im| im['src'] }
    cat = (['Бренды', 'KARE'] + @doc.css('.rs-breadcrumbs__item a').map { |a| a.text if !a.text.include?(title) && !a.text.include?('Главная') }.reject(&:blank?)).join('/')
    data = {
      sku: "KARE__#{@doc.css('.rs-product__article span').text}",
      title: title,
      full_title: @doc.css('.rs-product__title h4').text,
      desc: full_desc.join,
      cat: cat,
      charact: charact,
      price: price.to_i.floor,
      quantity_euro: quantity_euro.join.to_i,
      quantity: quantity.join.to_i,
      image: images.join(' '),
      url: @link,
      status: 'finish'
    }

    @kare.present? ? @kare.update!(data) : Kare.create!(data)
  end

  def get_proxy
    index = @kare.present? ? get_index : random_index
    link = Webshare.new.proxy_by_index(index)
    puts "proxy link => #{link}"
    link
  end

  def get_index
    check = @kare.id.to_s.size > 1 ? @kare.id.to_s[-2..-1].to_i : @kare.id
    check.zero? ? random_index : check
  end

  def random_index
    rand(1..100)
  end

end
