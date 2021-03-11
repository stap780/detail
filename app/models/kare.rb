require 'net/ftp'

class Kare < ApplicationRecord

  require 'open-uri'

  scope :kare_all_size, -> { order(:id).size }
  scope :kare_qt_not_null, -> { where('quantity > 0') }
  scope :kare_qt_not_null_size, -> { where('quantity > 0').size }
  scope :kare_cat, -> { order('cat DESC').select(:cat).uniq }
  scope :kare_image_nil, -> { where(image: [nil, '']).order(:id) }
  validates :sku, uniqueness: true

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
      puts 'Not file'
    end
    file = File.open(file_path)

    doc = Nokogiri::XML(file)

    categories = {}
    doc_categories = doc.xpath("//category")
    parent_category = ''

    doc_categories.each do |c|
      next if c.text == 'Каталог'
      if c["parentId"] == '11'
        parent_category = c.text
        next
      end
      categories[c["id"]] = "Kare/#{parent_category}/#{c.text}"
    end

    doc_products = doc.xpath("//offer")

    doc_products.each do |doc_product|

      charact = doc_product.xpath("param").map do |doc_param|
        name = doc_param['name']
        next if ['Количество для заказа', 'Количество в наличии в России', 'Артикул', 'Цвета', 'Материалы', 'Описание', 'Особенность'].include? name
        values_param = doc_param.text.gsub(', ', ',').split(',').join('##')
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
        sku: doc_product.at("param[name='Артикул']").text,
        title: doc_product.xpath("name").text.split(/\s\d+\*{1}\d+\*{1}\d+/).first,
        full_title: doc_product.xpath("name").text,
        desc: doc_product.at("param[name='Описание']")&.text,
        cat: categories[doc_product.xpath("categoryId").text.to_s],
        specialty: doc_product.at("param[name='Особенность']")&.text,
        charact: charact,
        price: price,
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
    products = Kare.all.order(:id)
    Kare.csv_param_selected(products, 'full')
  end

  def self.csv_param_selected(products, otchet_type)
    if otchet_type == 'selected'
      file = "#{Rails.public_path}"+'/kare_selected.csv'
    else
      file = "#{Rails.public_path}"+'/kare.csv'
    end
    check = File.file?(file)
    if check.present?
      File.delete(file)
    end

    if otchet_type == 'selected'
      file_ins = "#{Rails.public_path}"+'/ins_kare_selected.csv'
    else
      file_ins = "#{Rails.public_path}"+'/ins_kare.csv'
    end
    check = File.file?(file_ins)
    if check.present?
      File.delete(file_ins)
    end

    #создаём файл со статичными данными
    @tovs = Kare.where(id: products).order(:id)#.limit(10) #where('title like ?', '%Bellelli B-bip%')
    if otchet_type == 'selected'
      file = "#{Rails.root}/public/kare_selected.csv"
    else
      file = "#{Rails.root}/public/kare.csv"
    end
    CSV.open(file, 'w') do |writer|
      headers = ['fid','Артикул', 'Название товара', 'Дополнительное поле: Полное название товара', 'Дополнительное поле: Особенность',
                 'Полное описание', 'Цена продажи', 'Остаток', 'Остаток в Европе', 'Изображения',
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
          price = pr.price
          quantity = pr.quantity > 0 ? '' : 0
          quantity_euro = pr.quantity_euro
          image = pr.image
          cat = pr.cat.split('/')[0] || '' if pr.cat != nil
          cat1 = pr.cat.split('/')[1] || '' if pr.cat != nil
          cat2 = pr.cat.split('/')[2] || '' if pr.cat != nil
          cat3 = pr.cat.split('/')[3] || '' if pr.cat != nil

          writer << [fid, sku, title, full_title, specialty, desc, price, quantity, quantity_euro, image, cat, cat1, cat2, cat3, 'KARE' ]
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
    if otchet_type == 'selected'
      new_file = "#{Rails.public_path}"+'/ins_kare_selected.csv'
    else
      new_file = "#{Rails.public_path}"+'/ins_kare.csv'
    end
    CSV.open(new_file, "w") do |csv_out|
      rows = CSV.read(file, headers: true).collect do |row|
        row.to_hash
      end
      column_names = rows.first.keys
      csv_out << column_names
      CSV.foreach(file, headers: true ) do |row|
        fid = row[0]
        # puts fid
        vel = Kare.find_by_id(fid)
        if vel != nil
# 				puts vel.id
          if vel.charact.present? # Вид записи должен быть типа - "Длина рамы: 20 --- Ширина рамы: 30"
            vel.charact.split('---').each do |vp|
              key_value = vp.split(':')
              key = "Параметр: #{key_value[0].strip}"
              value = key_value[1].strip
              row[key] = value
            end
          end
        end
        csv_out << row
      end
    end
  end
end
