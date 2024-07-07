class Kare < ApplicationRecord
  require 'net/ftp'
  require 'open-uri'
  before_save :normalize_data_white_space
  after_create_commit { broadcast_prepend_to "kares" }
  after_update_commit { broadcast_replace_to "kares" }
  after_destroy_commit { broadcast_remove_to "kares" }


  scope :all_size, -> { order(:id).size }
  scope :kare_qt_not_null, -> { where('quantity > 0') }
  scope :qt_not_null_size, -> { where('quantity > 0').size }
  scope :kare_cat, -> { order('cat DESC').select(:cat).uniq }
  scope :kare_image_nil, -> { where(image: [nil, '']).order(:id) }
  scope :finished, -> { where(status: 'finish').order(:id) }
  # validates :sku, uniqueness: true
  validates :url, uniqueness: true

  STATUS = ["new","process","finish","error"]
  Proxy = {
      0 => "38.154.227.167:5868",
      1 => "185.199.229.156:7492",
      2 => "185.199.228.220:7300",
      3 => "185.199.231.45:8382",
      4 => "188.74.210.207:6286",
      5 => "188.74.183.10:8279",
      6 => "188.74.210.21:6100",
      7 => "45.155.68.129:8133",
      8 => "154.95.36.199:6893",
      9 => "45.94.47.66:8110" }


  def self.ransackable_attributes(auth_object = nil)
      Kare.attribute_names
  end
  def self.ransackable_associations(auth_object = nil)
    []
  end
  
  def self.pars
    service = KareCollectLinks.new.call
    if service
      Kare.order(:id).limit(100).each_with_index do |kare, index|
        puts "index => #{index}"
        proxy = Kare::Proxy[index.to_s.split('').last.to_i]
        # KareParsPageJob.perform_later(kare.url, proxy)
        KareParsPage.new(kare.url, proxy).call
      end
    end
  end

  def self.import
    puts "====>>>> START Import KARE === #{Time.now}"

    file_path = "#{Rails.root}/public/partners.xml"

    check = File.file?(file_path)
    if check.present?
      File.delete(file_path)
    end

    begin
      ftp = Net::FTP.new
      ftp.connect("kare-center.ru",21)
      ftp.login("partner03","MVAXkQ8j")
      ftp.passive = true
      ftp.getbinaryfile("partners.xml", "public/partners.xml")
      ftp.close
    rescue
      return
    end
    file = File.open(file_path)

    doc = Nokogiri::XML(file)

    doc_products = doc.xpath("//offer")

    return if doc_products.count == 0

    Kare.find_each(batch_size: 1000) do |kare|
      kare.update(quantity: 0)
    end

    categories = {}
    doc_categories = doc.xpath("//category")
    parent_category = ''

    doc_categories.each do |c|
      next if c.text == 'Каталог'
      if c["parentId"] == '11'
        parent_category = c.text
        next
      end
      categories[c["id"]] = "Бренды/KARE/#{parent_category}/#{c.text}"
    end

    doc_products.each do |doc_product|

      charact = doc_product.xpath("param").map do |doc_param|
        name = doc_param['name'].gsub(/, куб.м|, см/, '')
        next if ['Количество для заказа', 'Количество в наличии в России', 'Артикул', 'Цвета', 'Материалы', 'Описание', 'Особенность'].include? name
        values_param = doc_param.text.gsub(', ', ',').split(',').join('##')
        name = 'Материал' if name == 'Оригинальные материалы'
        name = 'Цвет' if name == 'Оригинальные цвета'
        "#{name}: #{values_param}"
      end.reject(&:nil?).join(' --- ')

      if doc_product.xpath("oldprice").present?
        number = doc_product.xpath("oldprice").text.to_f
        price = number - number/100
      else
        number = doc_product.xpath("price").text.to_f
        price = number - number/100
      end

      data = {
        sku: "KARE__#{doc_product.at("param[name='Артикул']").text}",
        title: doc_product.xpath("name").text.split(/\s[0-9]+,?[0-9]?\*{1}[0-9]+,?[0-9]?\*{1}[0-9]+,?[0-9]?/).first.gsub(/&quot;/, '"'),
        full_title: doc_product.xpath("name").text.gsub(/&quot;/, '"'),
        desc: doc_product.at("param[name='Описание']")&.text,
        cat: categories[doc_product.xpath("categoryId").text.to_s],
        specialty: doc_product.at("param[name='Особенность']")&.text,
        charact: charact,
        price: price.floor,
        quantity_euro: doc_product.at("param[name='Количество для заказа']").text.to_i,
        quantity: doc_product.at("param[name='Количество в наличии в России']").text.to_i,
        image: doc_product.xpath("picture").map(&:text).join(' '),
        url: doc_product.xpath("url").text,
        brand: doc_product.xpath("vendor").text
      }

      product = Kare.find_by_sku(data[:sku])

      if product.present?
        product.update(data)
      else
        Kare.create(data)
      end
    end
    puts "====>>>> FINISH Import KARE === #{Time.now}"
  end

  def self.csv_param
    products = Kare.all.finished
    Kare.csv_param_selected(products, 'full')
  end

  def self.csv_param_selected(products, otchet_type)
    file = otchet_type == 'selected' ? "#{Rails.public_path}/kare_selected.csv" : "#{Rails.public_path}/kare.csv"
    check_file = File.file?(file)
    File.delete(file) if check_file.present?

    file_ins = otchet_type == 'selected' ? "#{Rails.public_path}/ins_kare_selected.csv" : "#{Rails.public_path}/ins_kare.csv"
    check_file_ins = File.file?(file_ins)
    File.delete(file_ins) if check_file_ins.present?

    #создаём файл со статичными данными
    @tovs = Kare.where(id: products).order(:id)#.limit(10) #where('title like ?', '%Bellelli B-bip%')
    CSV.open(file, 'w') do |writer|
      headers = ['fid','Артикул', 'Название товара', 'Дополнительное поле: Полное название товара', 'Дополнительное поле: Особенность',
                 'Полное описание', 'Цена продажи', 'Остаток', 'Изображения',
                 'Подкатегория 1', 'Подкатегория 2', 'Подкатегория 3', 'Подкатегория 4', 'Параметр: Бренд' ]

      writer << headers
      @tovs.each do |pr|
        if pr.title != nil
          fid = pr.id
          sku = pr.sku
          title = pr.title
          full_title = pr.full_title
          specialty = pr.specialty
          desc = pr.desc
          price = pr.price.to_i - (pr.price.to_i * 1 / 100)
          quantity = pr.quantity > 0 ? pr.quantity : 0
          quantity_euro = pr.quantity_euro
          image = pr.image
          cat = pr.cat.split('/')[0] || '' if pr.cat != nil
          cat1 = pr.cat.split('/')[1] || '' if pr.cat != nil
          cat2 = pr.cat.split('/')[2] || '' if pr.cat != nil
          cat3 = pr.cat.split('/')[3] || '' if pr.cat != nil

          writer << [fid, sku, title, full_title, specialty, desc, price, quantity, image, cat, cat1, cat2, cat3, 'KARE' ]
        end
      end
    end #CSV.open

    #параметры в таблице записаны в виде - "Состояние: новый --- Вид: квадратный --- Объём: 3л --- Радиус: 10м"
    # дополняем header файла названиями параметров

    vparamHeader = []
    p = @tovs.select(:charact)
    p.each do |p|
      if p.charact.present?
        p.charact.split('---').each do |pa|
          vparamHeader << pa.split(':')[0].strip if pa != nil
        end
      end
    end
    addHeaders = vparamHeader.uniq

    # Load the original CSV file
    rows = CSV.read(file, headers: true).map do |row|
      row.to_hash
    end

    # Original CSV column headers
    column_names = rows.first.keys

    # Array of the new column headers
    addHeaders.each do |addH|
      additional_column_names = ['Параметр: '+addH]
      # Append new column name(s)
      column_names += additional_column_names
    end

    s = CSV.generate do |csv|
      csv << column_names
      rows.each do |row|
        values = row.values
        csv << values
      end
    end
    File.open(file, 'w') { |file| file.write(s) }
    # Overwrite csv file

    # заполняем параметры по каждому товару в файле
    CSV.open(file_ins, "w") do |csv_out|
      rows = CSV.read(file, headers: true).collect do |row|
        row.to_hash
      end
      column_names = rows.first.keys
      csv_out << column_names
      CSV.foreach(file, headers: true ) do |row|
        fid = row[0]
        puts "fid => #{fid.to_s}"
        vel = Kare.find_by_id(fid)
        if vel != nil
# 				puts vel.id
          if vel.charact.present? # Вид записи должен быть типа - "Длина рамы: 20 --- Ширина рамы: 30"
            vel.charact.split('---').each do |vp|
              puts "vp => #{vp.to_s}"
              key_value = vp.split(':')
              key = key_value[0].respond_to?("strip") ? "Параметр: #{key_value[0].strip}" : ''
              value = key_value[1].respond_to?("strip") ? key_value[1].strip : ''
              row[key] = value
            end
          end
        end
        csv_out << row
      end
    end
    
    Turbo::StreamsChannel.broadcast_replace_to(
      # User.find(current_user.id),
      "bulk_actions",
      target: "modal",
      template: "shared/success_bulk",
      layout: false,
      locals: {bulk_print: file_ins}
    )

  end

  private

  def normalize_data_white_space
	  self.attributes.each do |key, value|
	  	self[key] = value.squish if value.respond_to?("squish")
	  end
  end
  
end
