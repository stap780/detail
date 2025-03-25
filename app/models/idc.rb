class Idc < ApplicationRecord
  # include Turbo::Streams::ActionHelper
  require 'open-uri'

  after_create_commit { broadcast_prepend_to 'idcs' }
  after_update_commit { broadcast_replace_to 'idcs' }
  after_destroy_commit { broadcast_remove_to 'idcs' }

  scope :all_size, -> { order(:id).size }
  scope :product_qt_not_null, -> { where('quantity > 0') }
  scope :qt_not_null_size, -> { where('quantity > 0').size }
  scope :product_cat, -> { order('cat DESC').select(:cat).uniq }
  scope :product_image_nil, -> { where(image: [nil, '']).order(:id) }
  scope :not_archived, -> { where(archived: [false, nil]) }
  
  validates :sku, uniqueness: true
  validates :url, uniqueness: true, presence: true
  STATUS = %w[new process finish error].freeze


  def self.ransackable_attributes(auth_object = nil)
    Idc.attribute_names
  end
  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.csv_param
    Idc.csv_param_selected(Idc.all.order(:id), 'full')
  end

  def self.csv_param_selected(idcs, otchet_type)
    file = otchet_type == 'selected' ? "#{Rails.public_path}/idc_selected.csv" : "#{Rails.public_path}/idc.csv"

    check_file = File.file?(file)
    File.delete(file) if check_file.present?

    file_ins = otchet_type == 'selected' ? "#{Rails.public_path}/ins_idc_selected.csv" : "#{Rails.public_path}/ins_idc_new.csv"

    check_file_ins = File.file?(file_ins)
    File.delete(file_ins) if check_file_ins.present?

    # создаём файл со статичными данными
    @tovs = Idc.not_archived.where(id: idcs).order(:id) # .limit(10) #where('title like ?', '%Bellelli B-bip%')

    gab_data = {
      'H.' => 'Параметр: Высота',
      'ø' => 'Параметр: Диаметр',
      'D.' => 'Параметр: Глубина',
      'W.' => 'Параметр: Ширина',
      'SH.' => 'Параметр: Высота сидения',
      'AH.' => 'Параметр: Высота подлокотника',
      'L.' => 'Параметр: Длина'
    }


    CSV.open(file, 'w') do |writer|
      # headers = ['fid', 'Артикул', 'Название товара', 'Полное описание', 'Цена продажи', 'Старая цена', 'Остаток', 'Изображения', 'Подкатегория 1', 'Подкатегория 2', 'Подкатегория 3', 'Подкатегория 4', 'Параметр: Ширина', 'Параметр: Глубина', 'Параметр: Высота', 'Параметр: Глубина сиденья', 'Параметр: Высота сиденья', 'Параметр: Диаметр']
      headers = ['fid', 'Артикул', 'Название товара', 'Полное описание', 'Цена продажи', 'Старая цена', 'Остаток', 'Изображения', 'Подкатегория 1', 'Подкатегория 2', 'Подкатегория 3', 'Подкатегория 4'] + gab_data.values

      writer << headers
      @tovs.each do |pr|
        next if pr.title.nil?

        fid = pr.id
        sku = pr.sku
        title = pr.title.gsub('Eichholtz', '').gsub(sku, '')
        desc = pr.desc
        price = pr.price
        oldprice = pr.oldprice
        quantity = pr.quantity
        image = pr.image
        cat = pr.cat.present? ? pr.cat.split('---')[0] : ''
        cat1 = pr.cat.present? ? pr.cat.split('---')[1] : ''
        cat2 = pr.cat.present? ? pr.cat.split('---')[2] : ''
        cat3 = pr.cat.present? ? pr.cat.split('---')[3] : ''
        # charact_gab = pr.charact_gab

        # visota = ''
        # diametr = ''
        # glubina = ''
        # shirina = ''
        # visota_sid = ''
        # glubina_sid = ''

        # if charact_gab.present?
        #   if charact_gab.include?('A.') && charact_gab.include?('Б.')
        #     shirina = charact_gab.split('|')[0].gsub('A. ', '') if !charact_gab.split('|')[0].nil? && charact_gab.split('|')[0].include?('A.')
        #     glubina = charact_gab.split('|')[1].gsub('Б. ', '') if !charact_gab.split('|')[1].nil? && charact_gab.split('|')[1].include?('Б.')
        #     visota = charact_gab.split('|')[2].gsub('С. ', '') if !charact_gab.split('|')[2].nil? && charact_gab.split('|')[2].include?('С.')
        #     glubina_sid = charact_gab.split('|')[3].gsub('Д. ', '') if !charact_gab.split('|')[3].nil? && charact_gab.split('|')[3].include?('Д.')
        #     visota_sid = charact_gab.split('|')[4].gsub('Е. ', '') if !charact_gab.split('|')[4].nil? && charact_gab.split('|')[4].include?('Е.')
        #   end
        #   if charact_gab.include?('A.') && charact_gab.include?('B.')
        #     shirina = charact_gab.split('|')[0].gsub('A. ', '') if !charact_gab.split('|')[0].nil? && charact_gab.split('|')[0].include?('A.')
        #     glubina = charact_gab.split('|')[1].gsub('B. ', '') if !charact_gab.split('|')[1].nil? && charact_gab.split('|')[1].include?('B.')
        #     visota = charact_gab.split('|')[2].gsub('C. ', '') if !charact_gab.split('|')[2].nil? && charact_gab.split('|')[2].include?('C.')
        #     glubina_sid = charact_gab.split('|')[3].gsub('D. ', '') if !charact_gab.split('|')[3].nil? && charact_gab.split('|')[3].include?('D.')
        #     visota_sid = charact_gab.split('|')[4].gsub('E. ', '') if !charact_gab.split('|')[4].nil? && charact_gab.split('|')[4].include?('E.')
        #   end
        #   if charact_gab.split('x').size == 3 && charact_gab.include?('H.') && !charact_gab.include?('ø')
        #     shirina = charact_gab.split('x')[0]
        #     glubina = charact_gab.split('x')[1]
        #     visota = charact_gab.split('x')[2].gsub('H.', '')
        #   end
        #   if charact_gab.split('x').size == 3 && charact_gab.include?('высота') && !charact_gab.include?('ø')
        #     shirina = charact_gab.split('x')[0]
        #     glubina = charact_gab.split('x')[1]
        #     visota = charact_gab.split('x')[2].gsub('высота', '')
        #   end
        #   if charact_gab.split('x').size == 3 && charact_gab.include?('H.') && charact_gab.include?('ø')
        #     diametr = charact_gab.split('x')[0]
        #     glubina = charact_gab.split('x')[1]
        #     visota = charact_gab.split('x')[2].gsub('H.', '')
        #   end
        #   if charact_gab.split('x').size == 2 && charact_gab.include?('ø')
        #     diametr = charact_gab.split('x')[0].gsub('ø ', '')
        #     visota = charact_gab.split('x')[1].gsub('H.', '')
        #   end
        #   if charact_gab.split('x').size == 2 && !charact_gab.include?('ø')
        #     shirina = charact_gab.split('x')[0]
        #     glubina = charact_gab.split('x')[1]
        #   end
        # end
        # writer << [fid, sku, title, desc, price, oldprice, quantity, image, cat, cat1, cat2, cat3, shirina, glubina, visota, glubina_sid, visota_sid, diametr]

        charact_gab_array = pr.charact_gab.present? ? pr.charact_gab.split('x') : []
        p_values = []
        gab_data.each do |key, value|
          matching_char = charact_gab_array.find { |char| char.include?(key) }
          val = matching_char.gsub(key, '').strip if matching_char.present?
          p_values << val.to_s
        end
        writer << [fid, sku, title, desc, price, oldprice, quantity, image, cat, cat1, cat2, cat3]+p_values
      end
    end

    # параметры в таблице записаны в виде - "Состояние: новый --- Вид: квадратный --- Объём: 3л --- Радиус: 10м"
    # дополняем header файла названиями параметров

    vparam_header = []
    p = @tovs.select(:charact)
    p.each do |p|
      next if p.charact.nil?

      p.charact.split('---').each do |pa|
        vparam_header << pa.split(':')[0].strip unless pa.nil?
      end
    end
    addHeaders = vparam_header.uniq

    # Load the original CSV file
    rows = CSV.read(file, headers: true).collect do |row|
      row.to_hash
    end

    # Original CSV column headers
    column_names = rows.first.keys
    # Array of the new column headers
    addHeaders.each do |add_h|
      additional_column_names = ["Параметр: #{add_h}"]
      # Append new column name(s)
      column_names += additional_column_names
      s = CSV.generate do |csv|
        csv << column_names
        rows.each do |row|
          # Original CSV values
          values = row.values
          # Array of the new column(s) of data to be appended to row
          # additional_values_for_row = ['1']
          # values += additional_values_for_row
          csv << values
        end
      end
      File.open(file, 'w') { |file| file.write(s) }
    end
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
        # puts fid
        vel = Idc.find_by_id(fid)
        next if vel.nil?

        if vel.charact.present? # Вид записи должен быть типа - "Длина рамы: 20 --- Ширина рамы: 30"
          vel.charact.split('---').each do |vp|
            key = "Параметр: #{vp.split(':')[0].strip}"
            # if vp.split(':')[0].strip != 'Материал'
              value = vp.split(':')[1] #.remove('.').strip.split.map(&:capitalize).join(' ') if vp.split(':')[1] != nil
            # end
            # if vp.split(':')[0].strip == 'Материал'
            #   value = vp.split(':')[1].remove('.').strip.split(', ').map(&:capitalize).join(',').gsub(',', '##') if vp.split(':')[1] != nil
            # end
            row[key] = value
          end
        end
        csv_out << row
      end
    end

    # IdcMailer.ins_file(file_ins).deliver_now

    Turbo::StreamsChannel.broadcast_replace_to(
      # User.find(current_user.id),
      'bulk_actions',
      target: 'modal',
      template: 'shared/success_bulk',
      layout: false,
      locals: { bulk_print: file_ins }
    )
    Turbo::StreamsChannel.broadcast_action_to(
      'bulk_actions',
      action: 'open_modal',
      targets: '.modal'
    )
  end

  def self.clean_sm
    idcs = Idc.all
    idcs.each do |pr|
      pr.charact_gab = pr.charact_gab.gsub('cm', '').gsub('см', '')
      pr.save
    end
  end

  def self.pars
    urls = Idc.all.pluck(:url)
    urls.each do |url|
      Idc::ParsUrl.call(url)
    end
  end

end
