# This service class is responsible for importing data from the IDC website.
class Idc::Import  < ApplicationService
  BASE_URL = 'https://idcollection.ru/catalogue/producers/eichholtz'.freeze

  def initialize
    Idc.update_all(status: 'new', quantity: 0)
  end

  def call
    urls = collect_urls
    urls.uniq.each do |url|
      IdcParsUrlJob.perform_later("https://idcollection.ru#{url}")
    end
  end

  private

  def collect_urls
    page_number = 1
    max_page = Rails.env.development? ? 4 : fetch_max_page

    urls = []

    while page_number <= max_page
      cat_l = page_number == 1 ? "#{BASE_URL}" : "#{BASE_URL}/?PAGEN_4=page_number"
      response = RestClient.get(cat_l, { accept: 'text/html', 'Accept-Charset' => 'utf-8' })
      document = Nokogiri::HTML(response.body)
      document.css('.catalog-section__title-link').each do |link|
        urls << link['href']
      end
      page_number += 1
    end

    urls
  end

  def fetch_max_page
    response = RestClient.get(BASE_URL)
    document = Nokogiri::HTML(response.body)
    document.css('.pagenavigation__nav.pagenavigation__nav--next')[0]['data-max-page'].to_i
  end
end