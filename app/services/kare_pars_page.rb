# KareParsPage < ApplicationService
class KareParsPage < ApplicationService
  attr_reader :link, :doc, :data

  def initialize(link)
    @link = link
    @doc = nil
    @data = {}
    @kare = Kare.find_by_url(@link)
    @kare.update!(status: 'process', charact: '') if @kare.present?
    setup_logger
  end

  def call
    get_doc
    return unless check_product_page

    remove_double_info
    parse_doc
  end

  private

  def setup_logger
    @logger = Logger.new(Rails.root.join('log', 'kare_pars_page.log'))
    @logger.formatter = Logger::Formatter.new
  end

  def get_doc
    @logger.info 'Starting get_doc method'
    begin
      RestClient.proxy = get_proxy
      RestClient.get(@link, open_timeout: 240, verify_ssl: false) do |response, request, _result, &block|
        @logger.info("Send request - #{request.inspect}")
        case response.code
        when 200
          @logger.info("Successfully fetched URL: #{@link}")
          @doc = Nokogiri::HTML(response.body)
        when 301, 302, 307
          response.follow_redirection
        when 400, 404, 423, 429
          @logger.error("HTTP error for URL: #{@link} - #{response.code} - #{response}")
          handle_error_status
        else
          @logger.error("Unhandled response code for URL: #{@link}")
          handle_error_status
          response.return!(&block)
        end
      end
    rescue RestClient::Exceptions::Timeout, RestClient::Exceptions::OpenTimeout => e
      @logger.error("Timeout error for URL: #{@link} - #{e.message}")
      handle_error_status
    rescue StandardError => e
      @logger.error("Unexpected error for URL: #{@link} - #{e.message}")
      handle_error_status
    end
  end

  def handle_error_status
    @kare.update!(status: 'error') if @kare.present?
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
