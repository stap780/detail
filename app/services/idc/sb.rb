# This service is responsible for fetching offers from the SearchBooster API.
class Idc::Sb < ApplicationService
  BASE_URL = 'https://api.searchbooster.net/api/'.freeze

  def initialize()
    @apiId = '1f2063d6-d765-425a-bed3-e6ab10fbcf71'
    Idc.update_all(status: 'new', quantity: 0)
  end

  def call
    offers = fetch_offers
    offers.each do |offer|
      data = {
        title: offer['name'],
        sku: offer['offerCode'],
        url: offer['url'].split('?').first,
        price: offer['price'],
        oldprice: offer['oldPrice']
      }

      puts "data: #{data}"
      Idc.where(sku: data[:sku]).first_or_create!(data)
      IdcParsUrlJob.perform_later(data[:url])
    end
  end

  private

  def fetch_offers
    skip = 0
    limit = 100
    offers = []
    max = Rails.env.development? ? 4 : fetch_max

    while skip < max
      url = build_url(limit, skip)
      response = RestClient.get(url)
      data = JSON.parse(response.body)

      offers.concat(data['offers']) if data['offers']
      skip += limit
    end

    offers
  end

  def build_url(limit = 100, skip = 0)
    data = [
      { key: 'query', value: 'eichholtz' },
      { key: 'limit', value: limit },
      { key: 'skip', value: skip },
      { key: 'firstInSession', value: 1 },
      { key: 'locale', value: 'ru' },
      { key: 'userId', value: 'N-sgOrNkh91aTyaNdAKEG_AfiCKEZKJW3gcyaxwOw92|2.10.17.50' },
      { key: 'client', value: 'idcollection.ru' }
    ]
    search = data.map{|s| [s[:key],s[:value]].join('=')}.join('&')
    "#{BASE_URL}#{@apiId}/search?#{search}"
  end

  def fetch_max
    url = build_url(10,0)
    response = RestClient.get(url)
    data = JSON.parse(response.body)
    data['hits']
  end

end