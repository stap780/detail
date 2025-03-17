# Description: This service is used to interact with the Webshare API.
class Webshare < ApplicationService
  BASE_URL = 'https://proxy.webshare.io/api/v2'.freeze

  def initialize
    @api_token = Rails.application.credentials.webshare.api_key
  end

  def collect_proxy_list
    proxy_list = []
    file_name = 'proxy_list.txt'
    remove_file(file_name)
    download_proxy_list_file(file_name)

    File.open(Rails.root.join('public', file_name), 'r').each_line do |line|
      proxy = line.split(':')
      proxy = {
        ip: proxy[0],
        port: proxy[1],
        username: Rails.application.credentials.webshare.username,
        password: Rails.application.credentials.webshare.password
      }
      proxy_list << proxy
    end

    proxy_list
  end

  def config_info
    response = RestClient.get("#{BASE_URL}/proxy/config/", headers )
    JSON.parse(response.body)
  end

  def proxy_by_index(index)
    response = RestClient.get("#{BASE_URL}/proxy/list/?mode=direct&page=#{index}&page_size=1", headers)
    data = JSON.parse(response.body)['results']
    username = Rails.application.credentials.webshare.username
    password = Rails.application.credentials.webshare.password
    "http://#{username}:#{password}@#{data[0]['proxy_address']}:#{data[0]['port']}"
  end

  private

  def headers
    { Authorization: "Token #{@api_token}" }
  end

  def proxy_list_download_token
    config = config_info
    config['proxy_list_download_token']
  end

  def download_proxy_list_file(file_name)
    token = proxy_list_download_token
    response = RestClient.get("#{BASE_URL}/proxy/list/download/#{token}/-/any/username/direct/-/")
    File.open(Rails.root.join('public', file_name), 'wb') do |file|
      file.write(response.body)
    end
  end

  def remove_file(file_name)  
    file_path = Rails.root.join('public', file_name)
    File.delete(file_path) if File.exist?(file_path)
  end

end