class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  # GET /products
  # GET /products.json
  def index
    if params[:q].present?
      new_q = {}
      params[:q].each do |k,v|
        if k == 'quantity_in'
          puts v
          if v == "0"
            value = 0
          end
          if v == "1"
            value = Array(1..200)
          end
            new_q[k] = value
        else
        new_q[k] = v
        end
      end
      # puts new_q
    end
    @search = Product.ransack(new_q)
    @search.sorts = 'id desc' if @search.sorts.empty?
    @products = @search.result.paginate(page: params[:page], per_page: 100)
    # if params['otchet_type'] == 'selected'
    #   Product.csv_param_selected( params['selected_products'], params['otchet_type'])
    #   new_file = "#{Rails.public_path}"+'/ins_detail_selected.csv'
    #   send_file new_file, :disposition => 'attachment'
    # end
  end

  # GET /products/1
  # GET /products/1.json
  def show
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        format.html { redirect_to @product, notice: 'Product was successfully created.' }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
      flash.now[:success] = 'Product was successfully destroyed.'
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@product),
          render_turbo_flash
        ]
      end
    end
  end

  def edit_multiple
    puts params[:product_ids].present?
    if params[:product_ids].present?
			@products = Product.find(params[:product_ids])
      respond_to do |format|
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to products_url, notice: 'select products' }
        format.json { head :no_content }
        flash.now[:success] = 'select products'
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    end
  end

  def update_multiple
    @products = Product.find(params[:product_ids])
		@products.each do |pr|
			attr = params[:product_attr]
			attr.each do |key,value|
				if key.to_s == 'picture'
					# if value.to_i == 1
					# product_id = pr.id
					#puts product_id
					# Product.productimage(product_id)
					# end
				end
				if key.to_s != 'picture'
					if !value.blank?
					pr.update_attributes(key => value)
            if key.to_s == 'pricepr'
              Product.update_pricepr(pr.id)
            end
					end
				end
			end
		end
		flash[:notice] = 'Данные обновлены'
		redirect_to :back
  end

  def bulk_export
    if params[:product_ids].present?
      # new_file = "#{Rails.public_path}"+'/ins_idcollection_selected.csv'
      respond_to do |format|
        format.html { redirect_to products_url, notice: 'Product print' }
        format.json { head :no_content }
        flash.now[:success] = 'Product print.'
        format.turbo_stream
      end
      products = Product.where(id: params[:product_ids].split(','))
      Product.csv_param_selected(products, 'selected')
    else
      respond_to do |format|
        format.html { redirect_to products_url, notice: 'select products' }
        format.json { head :no_content }
        flash.now[:success] = 'select products'
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    end
  end

  def delete_selected
    if params[:product_ids].present?
      products = Product.where(id: params[:product_ids].split(','))
      products.each do |product|
        product.destroy
      end
      respond_to do |format|
        format.html { redirect_to products_url, notice: 'Products was successfully destroyed.' }
        format.json { head :no_content }
        flash.now[:success] = 'Products was successfully destroyed.'
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to products_url, notice: 'select products' }
        format.json { head :no_content }
        flash.now[:success] = 'select products'
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    end
  end

  def import
    ProductImportJob.perform_later
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'Задача обновления каталога запущена' }
      format.json { head :no_content }
      flash.now[:success] = 'Задача обновления каталога запущена'
      format.turbo_stream do
        render turbo_stream: [
          render_turbo_flash
        ]
      end
    end
  end

  def csv_param
    ProductCsvParamJob.perform_later
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'Запустили' }
      format.json { head :no_content }
      flash.now[:success] = 'Запустили'
      format.turbo_stream do
        render turbo_stream: [
          render_turbo_flash
        ]
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.require(:product).permit(:status, :sku, :title, :desc, :cat, :charact, :charact_gab, :oldprice, :price, :quantity, :image, :url)
    end
end
