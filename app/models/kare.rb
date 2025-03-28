class Kare < ApplicationRecord
  require 'net/ftp'
  require 'open-uri'
  before_save :normalize_data_white_space
  after_create_commit { broadcast_prepend_to 'kares' }
  after_update_commit { broadcast_replace_to 'kares' }
  after_destroy_commit { broadcast_remove_to 'kares' }


  scope :all_size, -> { order(:id).size }
  scope :kare_qt_not_null, -> { where('quantity > 0') }
  scope :qt_not_null_size, -> { where('quantity > 0').size }
  scope :kare_cat, -> { order('cat DESC').select(:cat).uniq }
  scope :kare_image_nil, -> { where(image: [nil, '']).order(:id) }
  scope :finished, -> { where(status: 'finish').order(:id) }
  # validates :sku, uniqueness: true
  validates :url, uniqueness: true

  STATUS = ["new","process","finish","error"]

  def self.ransackable_attributes(auth_object = nil)
    Kare.attribute_names
  end

def self.ransackable_associations(auth_object = nil)
  []
end

def self.ransackable_scopes(auth_object = nil)
  [:lt_1, :gt_0]
end

def self.lt_1
  Kare.where('quantity = 0')
end

  def self.gt_0
    Kare.kare_qt_not_null
  end

  def self.pars
    service = KareCollectLinks.new.call
    if service
      Kare.order(:id).each do |kare|
        KareParsPageJob.perform_later(kare.url)
      end
    end
  end

  def self.csv_param
    Kare.csv_param_selected(Kare.all.finished, 'full')
  end

  def self.csv_param_selected(products, otchet_type)
    file = otchet_type == 'selected' ? "#{Rails.public_path}/kare_selected.csv" : "#{Rails.public_path}/kare.csv"
    check_file = File.file?(file)
    File.delete(file) if check_file.present?

    file_ins = otchet_type == 'selected' ? "#{Rails.public_path}/ins_kare_selected.csv" : "#{Rails.public_path}/ins_kare_new.csv"
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

          writer << [fid, sku, title, full_title, specialty, desc, price, quantity, image, cat, cat1, cat2, cat3, 'KARE']
        end
      end
    end #CSV.open

    # параметры в таблице записаны в виде - "Состояние: новый --- Вид: квадратный --- Объём: 3л --- Радиус: 10м"
    # дополняем header файла названиями параметров

    vparamHeader = []
    p = @tovs.select(:charact)
    p.each do |p|
      next unless p.charact.present?

      p.charact.split('---').each do |pa|
        vparamHeader << pa.split(':')[0].strip if pa != nil
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
    CSV.open(file_ins, 'w') do |csv_out|
      rows = CSV.read(file, headers: true).collect do |row|
        row.to_hash
      end
      column_names = rows.first.keys
      csv_out << column_names
      CSV.foreach(file, headers: true) do |row|
        fid = row[0]
        vel = Kare.find_by_id(fid)
        next if vel.nil?

        if vel.charact.present?
          # NOTICE Вид записи должен быть типа - 'Длина рамы: 20 --- Ширина рамы: 30'
          vel.charact.split('---').each do |vp|
            key_value = vp.split(':')
            key = key_value[0].respond_to?('strip') ? "Параметр: #{key_value[0].strip}" : ''
            value = key_value[1].respond_to?('strip') ? key_value[1].strip.gsub('см<sup>3</sup>', '').gsub('см', '').gsub('кг', '') : ''
            value_size = value.split(' ').size
            if key == 'Параметр: Материал'
              value = value_size == 1 ? value.split(' ').map(&:capitalize).join(' ') : ''
            end
            row[key] = value
          end
        end

        csv_out << row
      end
    end

    Turbo::StreamsChannel.broadcast_replace_to(
      # User.find(current_user.id),
      'bulk_actions',
      target: 'modal',
      template: 'shared/success_bulk',
      layout: false,
      locals: { bulk_print: file_ins }
    )

  end

  private

  def normalize_data_white_space
	  self.attributes.each do |key, value|
	  	self[key] = value.squish if value.respond_to?("squish")
	  end
  end
  
end
