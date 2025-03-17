class KareCollectLinks < ApplicationService
  require 'open-uri'

  attr_reader :link, :product_links

  def initialize
    @link = "https://karedesign.ru/sitemap_index.xml"
    @product_links = []
  end

    def call
        collect_links
        status = create_kare
        status == true ? true : false
        # true
    end

    private 

    def collect_links
        doc = Nokogiri::HTML(URI.open(@link))
        xml_products_links = doc.xpath('//loc').map{|loc| loc.text if loc.text.include?('product-')}.reject(&:blank?) #doc.xpath('//loc').collect(&:text)
        collect_products_links = []
        xml_products_links.each do |link|
            children_doc = Nokogiri::HTML(URI.open(link))
            search_links = children_doc.css('loc').map{|l| l.text if !l.text.include?('uploads')}.reject(&:blank?)
            collect_products_links.push(*search_links) #products_links += search_links
        end
        @product_links = collect_products_links
    end

    def create_kare
        return false if @product_links.size == 0
        @product_links.each do |link|
            s_kare = Kare.find_by_url(link)
            Kare.create(url: link) if !s_kare.present?
        end
        true
    end


end