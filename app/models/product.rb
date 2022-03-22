class Product < ApplicationRecord

  require 'open-uri'

  scope :product_all_size, -> { order(:id).size }
  scope :product_qt_not_null, -> { where('quantity > 0') }
  scope :product_qt_not_null_size, -> { where('quantity > 0').size }
  scope :product_cat, -> { order('cat DESC').select(:cat).uniq }
  scope :product_image_nil, -> { where(image: [nil, '']).order(:id) }
  validates :sku, uniqueness: true

  def self.import
    puts 'start import '+Time.now.in_time_zone('Moscow').to_s
    Product.update_all(quantity: 0)
    url = "https://idcollection.ru/catalogue/producers/eichholtz"
    doc = Nokogiri::HTML(open(url, :read_timeout => 50))
		paginate_number = doc.css(".pagenavigation__nav.pagenavigation__nav--next")[0]['data-max-page']
    if Rails.env.development?
      count = 4
    else
      count = paginate_number.presence || '1'
    end
    puts count
    page_array = Array(1..count.to_i)
		page_array.each do |page|
      puts 'page '+page.to_s
      cat_l = url+"?PAGEN_2="+page.to_s
      cat_doc = Nokogiri::HTML(open(cat_l, :read_timeout => 50))
        product_urls = cat_doc.css('.catalog-section__title-link')
        product_urls.each do |purl|
          pr_url = 'https://idcollection.ru'+purl['href']
          # pr_doc = Nokogiri::HTML(open(pr_url, :read_timeout => 50))
          RestClient::Request.execute( url: pr_url, method: :get, verify_ssl: false ) { |response, request, result, &block|
            case response.code
      			when 200
              pr_doc = Nokogiri::HTML(response)
          puts pr_url
          title= pr_doc.css('h1').text
          # puts title
          desc = pr_doc.css('.catalog-element-description__text').text.strip
          cat_array = pr_doc.css('.breadcrumbs__element--title').map{|b| b.text.split(' ').join(' ') }.reject{|b| b == 'Каталог' || b == 'Категория' }
          cat = cat_array.join('---')

          sku_array = []
          charact_gab_array = []
          characts_array = []
          pr_doc.css('.element-popups__content .first .content-item__element').each do |file_charact|
            key = file_charact.inner_html.split('<span>').first.strip
            value = file_charact.text.remove("#{key}").squish if file_charact.text.remove("#{key}").respond_to?("squish")
            sku_array.push(value) if key == 'Артикул'
            charact_gab_array.push(value) if key == 'Габариты'
            characts_array.push(key+' : '+value.to_s) if key != 'Артикул' and key != 'Габариты'
          end
          charact = characts_array.join('---')
          sku = sku_array.join()
          charact_gab = charact_gab_array.join().gsub('cm', '').gsub('см', '')

          oldprice_price_node = pr_doc.css('.element-info__default-price .discount')
          oldprice = oldprice_price_node.present? ? oldprice_price_node.text.strip.gsub(' ','').gsub('руб.','').gsub('.0','') : 0
          price_node = pr_doc.css('.element-info__default-price .price')
          price = price_node.present? ? price_node.text.strip.gsub(' ','').gsub('руб.','').gsub('.0','') : 0
          quantity_node = pr_doc.css('.element-info__availability-have')
          quantity = quantity_node.present? ? quantity_node.text.split(':').last.strip.gsub(' шт.','') : 0
          picts = []
    			pict_main = pr_doc.css('.element-slider__image').size > 0 ? pr_doc.css('.element-slider__image')[0]['src'] : ''
    			picts.push(pict_main)
          thumb_node = pr_doc.css('.element-slider__nav-image img')
    			pict_thumbs = thumb_node.present? ? thumb_node.map{ |p| p["src"] } : [""]
    			picts |= pict_thumbs
          image = picts.map{ |a| "https://idcollection.ru"+a.gsub("197_140_1","800_800_1") }.join(' ')

          product = Product.find_by_sku(sku)
          if product.present?
            product.update_attributes(title: title, desc: desc, cat: cat, charact: charact, charact_gab: charact_gab, oldprice: oldprice, price: price, quantity: quantity, image: image, url: pr_url)
          else
            Product.create(sku: sku, title: title, desc: desc, cat: cat, charact: charact, charact_gab: charact_gab, oldprice: oldprice, price: price, quantity: quantity, image: image, url: pr_url)
          end
        when 404
  	# 			puts response
  				puts 'error 404'
        when 503
  	# 			puts response
  				puts 'error 503 break'
          break
  			else
  				response.return!(&block)
  			end
  			}

        end
    end

    productcount = Product.product_qt_not_null_size ||= "0"
		productall = Product.product_all_size ||= "0"
    # ProductMailer.downloadproduct_product(productcount, productall).deliver_now
    puts 'end import '+Time.now.in_time_zone('Moscow').to_s
  end

  def self.csv_param
    products = Product.all.order(:id)
    Product.csv_param_selected(products, 'full')
  end

  def self.csv_param_selected(products, otchet_type)
    if otchet_type == 'selected'
      file = "#{Rails.public_path}"+'/detail_selected.csv'
    else
		  file = "#{Rails.public_path}"+'/detail.csv'
    end
		check = File.file?(file)
		if check.present?
			File.delete(file)
		end

    if otchet_type == 'selected'
      file_ins = "#{Rails.public_path}"+'/ins_detail_selected.csv'
    else
		  file_ins = "#{Rails.public_path}"+'/ins_detail.csv'
    end
		check = File.file?(file_ins)
		if check.present?
			File.delete(file_ins)
		end

		#создаём файл со статичными данными
		@tovs = Product.where(id: products).order(:id)#.limit(10) #where('title like ?', '%Bellelli B-bip%')
    if otchet_type == 'selected'
      file = "#{Rails.root}/public/detail_selected.csv"
    else
      file = "#{Rails.root}/public/detail.csv"
    end
		CSV.open( file, 'w') do |writer|
		headers = ['fid','Артикул', 'Название товара', 'Полное описание', 'Цена продажи', 'Старая цена' , 'Остаток', 'Изображения', 'Подкатегория 1', 'Подкатегория 2', 'Подкатегория 3', 'Подкатегория 4', 'Параметр: Ширина', 'Параметр: Глубина', 'Параметр: Высота', 'Параметр: Глубина сиденья', 'Параметр: Высота сиденья', 'Параметр: Диаметр' ]

		writer << headers
		@tovs.each do |pr|
			if pr.title != nil
        puts "pr.id - "+pr.id.to_s
				fid = pr.id
				sku = pr.sku
        title = pr.title.gsub('Eichholtz','').gsub(sku,'')
        desc = pr.desc
        price = pr.price
        oldprice = pr.oldprice
        quantity = pr.quantity
				image = pr.image
				cat = pr.cat.split('---')[0] || '' if pr.cat != nil
				cat1 = pr.cat.split('---')[1] || '' if pr.cat != nil
				cat2 = pr.cat.split('---')[2] || '' if pr.cat != nil
				cat3 = pr.cat.split('---')[3] || '' if pr.cat != nil
        charact_gab = pr.charact_gab

        shirina = ''
        glubina = ''
        visota = ''
        glubina_sid = ''
        visota_sid = ''
        diametr = ''

        if charact_gab.include?('A.') and charact_gab.include?('Б.')
          shirina = charact_gab.split('|')[0].gsub('A. ', '') if !charact_gab.split('|')[0].nil? and charact_gab.split('|')[0].include?('A.')
          glubina = charact_gab.split('|')[1].gsub('Б. ', '') if !charact_gab.split('|')[1].nil? and charact_gab.split('|')[1].include?('Б.')
          visota = charact_gab.split('|')[2].gsub('С. ', '') if !charact_gab.split('|')[2].nil? and charact_gab.split('|')[2].include?('С.')
          glubina_sid = charact_gab.split('|')[3].gsub('Д. ', '') if !charact_gab.split('|')[3].nil? and charact_gab.split('|')[3].include?('Д.')
          visota_sid = charact_gab.split('|')[4].gsub('Е. ', '') if !charact_gab.split('|')[4].nil? and charact_gab.split('|')[4].include?('Е.')
        end
        if charact_gab.include?('A.') and charact_gab.include?('B.')
          shirina = charact_gab.split('|')[0].gsub('A. ', '') if !charact_gab.split('|')[0].nil? and charact_gab.split('|')[0].include?('A.')
          glubina = charact_gab.split('|')[1].gsub('B. ', '') if !charact_gab.split('|')[1].nil? and charact_gab.split('|')[1].include?('B.')
          visota = charact_gab.split('|')[2].gsub('C. ', '') if !charact_gab.split('|')[2].nil? and charact_gab.split('|')[2].include?('C.')
          glubina_sid = charact_gab.split('|')[3].gsub('D. ', '') if !charact_gab.split('|')[3].nil? and charact_gab.split('|')[3].include?('D.')
          visota_sid = charact_gab.split('|')[4].gsub('E. ', '') if !charact_gab.split('|')[4].nil? and charact_gab.split('|')[4].include?('E.')
        end
        if charact_gab.split('x').size == 3 and charact_gab.include?('H.') and !charact_gab.include?('ø')
          shirina = charact_gab.split('x')[0]
          glubina = charact_gab.split('x')[1]
          visota = charact_gab.split('x')[2].gsub('H.', '')
        end
        if charact_gab.split('x').size == 3  and charact_gab.include?('высота') and !charact_gab.include?('ø')
          shirina = charact_gab.split('x')[0]
          glubina = charact_gab.split('x')[1]
          visota = charact_gab.split('x')[2].gsub('высота', '')
        end
        if charact_gab.split('x').size == 3  and charact_gab.include?('H.') and charact_gab.include?('ø')
          diametr = charact_gab.split('x')[0]
          glubina = charact_gab.split('x')[1]
          visota = charact_gab.split('x')[2].gsub('H.', '')
        end
        if charact_gab.split('x').size == 2 and charact_gab.include?('ø')
          diametr = charact_gab.split('x')[0].gsub('ø ', '')
          visota = charact_gab.split('x')[1].gsub('H.', '')
        end
        if charact_gab.split('x').size == 2 and !charact_gab.include?('ø')
          shirina = charact_gab.split('x')[0]
          glubina = charact_gab.split('x')[1]
        end
        writer << [fid, sku, title, desc, price, oldprice, quantity, image, cat, cat1, cat2, cat3, shirina, glubina, visota, glubina_sid, visota_sid, diametr ]
				end
			end
		end #CSV.open

		#параметры в таблице записаны в виде - "Состояние: новый --- Вид: квадратный --- Объём: 3л --- Радиус: 10м"
		# дополняем header файла названиями параметров

		vparamHeader = []
		p = @tovs.select(:charact)
		p.each do |p|
			if p.charact != nil
				p.charact.split('---').each do |pa|
					vparamHeader << pa.split(':')[0].strip if pa != nil
				end
			end
		end
		addHeaders = vparamHeader.uniq

		# Load the original CSV file
		rows = CSV.read(file, headers: true).collect do |row|
			row.to_hash
		end

		# Original CSV column headers
		column_names = rows.first.keys
		# Array of the new column headers
		addHeaders.each do |addH|
    		additional_column_names = ['Параметр: '+addH]
    		# Append new column name(s)
    		column_names += additional_column_names
    			s = CSV.generate do |csv|
    				csv << column_names
    				rows.each do |row|
    					# Original CSV values
    					values = row.values
    					# Array of the new column(s) of data to be appended to row
    	# 				additional_values_for_row = ['1']
    	# 				values += additional_values_for_row
    					csv << values
    				end
    			end
    		File.open(file, 'w') { |file| file.write(s) }
		end
		# Overwrite csv file

		# заполняем параметры по каждому товару в файле
    if otchet_type == 'selected'
      new_file = "#{Rails.public_path}"+'/ins_detail_selected.csv'
    else
		  new_file = "#{Rails.public_path}"+'/ins_detail.csv'
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
			vel = Product.find_by_id(fid)
				if vel != nil
# 				puts vel.id
					if vel.charact.present? # Вид записи должен быть типа - "Длина рамы: 20 --- Ширина рамы: 30"
					vel.charact.split('---').each do |vp|
						key = 'Параметр: '+vp.split(':')[0].strip
            if vp.split(':')[0].strip != 'Материал'
						  value = vp.split(':')[1].remove('.').strip.split.map(&:capitalize).join(' ') if vp.split(':')[1] !=nil
            end
            if vp.split(':')[0].strip == 'Материал'
              value = vp.split(':')[1].remove('.').strip.split(', ').map(&:capitalize).join(',').gsub(',','##') if vp.split(':')[1] !=nil
            end
						row[key] = value
					end
					end
				end
			csv_out << row
			end
		end

    # ProductMailer.ins_file(new_file).deliver_now
	end

  def self.clean_sm
    products = Product.all
    products.each do |pr|
      pr.charact_gab = pr.charact_gab.gsub('cm', '').gsub('см', '')
      pr.save
    end
  end

end
