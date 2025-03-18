# class KareCollectLinks < ApplicationService
class KareCollectLinks < ApplicationService
  require 'open-uri'

  attr_reader :link, :product_links

  def initialize
    @link = 'https://karedesign.ru/sitemap_index.xml'
    @product_links = []
  end

  def call
    collect_links
    create_kare # true or false
  end
  
  private

  def collect_links
    response = RestClient.get(@link)
    doc = Nokogiri::HTML(response.body)
    xml_products_links = doc.xpath('//loc').map{|loc| loc.text if loc.text.include?('product-')}.reject(&:blank?)
    collect_products_links = []
    xml_products_links.each do |link|
      resp = RestClient.get(link)
      children_doc = Nokogiri::HTML(resp.body)
      search_links = children_doc.css('loc').map{|l| l.text unless l.text.include?('uploads')}.reject(&:blank?)
      collect_products_links.push(*search_links) # products_links += search_links
    end
    @product_links = collect_products_links
  end

  def create_kare
    return false if @product_links.size.zero?

    @product_links.each do |link|
      s_kare = Kare.find_by_url(link)
      Kare.create!(url: link) unless s_kare.present?
    end
    true
  end

end