class KareParsPage < ApplicationService
    require 'open-uri'
    require 'faraday'

    attr_reader :link, :doc, :data
    
    def initialize(link,proxy)
        puts "initialize => link - #{link} , proxy - #{proxy}"
        @link = link
        @doc
        @data = {}
        @proxy = proxy
    end

    def call
        sleep 0.3
        puts "sleep 0.3"
        set_process
        get_doc
        puts "end get_doc"
        return if !check_product_page
        puts "end check_product_page"
        remove_double_info
        puts "end remove_double_info"
        collect_data
        puts "end collect_data"
        create_update
    end

    private

    def set_process
        kare = Kare.find_by_url(@link)
        kare.update(status: 'process') if kare.present?
    end

    def get_doc
        puts "start get_doc"
        proxy_ip = @proxy
        proxy_username = Rails.application.credentials.proxy_username
        proxy_password = Rails.application.credentials.proxy_password

        conn = Faraday.new( url: @link,
                            :ssl=>{verify:false},
                            :proxy => "http://#{proxy_username}:#{proxy_password}@#{proxy_ip}"
                            ) do |faraday|
            # Set the Authorization header with the Bearer token
            # faraday.request :authorization, 'Bearer', 'MySecretKey'
        end
        response = conn.get #('/posts.json')
        # response = conn.get('/api/v1/home/index')
        puts response
        response.headers
        puts response.status
        response.body
        @doc = Nokogiri::HTML(response.body) # body_json = JSON.parse(response.body)
    end

    def check_product_page
        puts "start check_product_page"
        @doc.css('.rs-product__card').present? && @doc.css('.rs-product__card').inner_html.present?
    end

    def remove_double_info
        puts "start remove_double_info"
        @doc.css('.modal').remove
    end

    def collect_data
        puts "start collect_data"
        title = @doc.css('.rs-product__title h4').text
        if @doc.css('.rs-product__price_new').present?
            price = @doc.css('.rs-product__price_new').text.split('').reject(&:blank?).join.remove('₽')
        else
            price = @doc.css('.rs-product__price_actual').text.split('').reject(&:blank?).join.remove('₽')
        end

        desc = @doc.css('.tabs__body .rs-product__block').map{|line| line.css('.small-text').inner_html if line.css('h4').text.include?('Описание')}
        material = @doc.css('.rs-product__characteristics_item').map{|line| 'Материал:'+line.css('.small-text').text.gsub(':','-').strip if line.css('h6').text.include?('Материал:')}.reject(&:blank?)
        # sizes = @doc.css('.rs-product__characteristics_item').map{|line| line.css('ul li') if line.css('h6').text.include?('Упаковка и габариты:')}.reject(&:blank?).flatten
        # sizes.map{|s| s.text}.join('---')
        sizes = @doc.css('.rs-product__characteristics_item ul li').map{|line| line.inner_html.remove(':').gsub('<span>',':').remove('</span>').squish if line.inner_html && line.inner_html.respond_to?("squish")}
        # puts 'material'
        # puts material.to_s
        # puts  '==========='
        # puts 'sizes'
        # puts sizes.to_s
        charact = (sizes + material).join('---')
        extra = @doc.css('.tabs__body .rs-product__block').map{|line| line.css('.rs-product__links').inner_html if line.css('h4').text.include?('Инструкция')}
        full_desc = desc + extra

        quantity_euro = []
        quantity = []
        @doc.css('.stock-confirmed').each do |stock|
            value = stock.css('.quantity-info h6').text.split('').reject(&:blank?).join.remove('шт')
            quantity.push(value) if stock.css('.store-info h6').text.include?('России')
            quantity_euro.push(value) if stock.css('.store-info h6').text.include?('Мюнхене')
        end
        images = @doc.css('.rs-product__slide img').map{|im| im['src']}
        cat = (['Бренды','KARE']+@doc.css('.rs-breadcrumbs__item a').map{|a| a.text if !a.text.include?(title) && !a.text.include?('Главная')}.reject(&:blank?)).join('/')
        
        @data = {
            sku: "KARE__#{@doc.css('.rs-product__article span').text}",
            title: title,
            full_title: @doc.css('.rs-product__title h4').text,
            desc: full_desc.join,
            cat: cat,
            # specialty: doc_product.at("param[name='Особенность']")&.text,
            charact: charact,
            price: price.to_i.floor,
            quantity_euro: quantity_euro.join.to_i,
            quantity: quantity.join.to_i,
            image: images.join(' '),
            # brand: doc_product.xpath("vendor").text,
            url: @link
          }
    end

    def create_update
        puts "start create_update"
        kare = Kare.find_by_url(@link)
        kare.present? ? kare.update(@data.merge(status: 'finish')) : Kare.create(@data.merge(status: 'finish'))
        # puts "end create_update"
    end
    
end