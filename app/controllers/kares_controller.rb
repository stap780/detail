class KaresController < ApplicationController

  before_action :authenticate_user!
  before_action :set_kare, only: [:show, :edit, :update, :destroy]

  # GET /products
  # GET /products.json
  def index
    # if params[:q].present?
    #   new_q = {}
    #   params[:q].each do |k,v|
    #     if k == 'quantity_in'
    #       puts v
    #       if v == "0"
    #         value = 0
    #       end
    #       if v == "1"
    #         value = Array(1..200)
    #       end
    #       new_q[k] = value
    #     else
    #       new_q[k] = v
    #     end
    #   end
    #   # puts new_q
    # end
    @search = Kare.ransack(params[:q])
    @search.sorts = 'id desc' if @search.sorts.empty?
    @kares = @search.result.paginate(page: params[:page], per_page: 100)
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
    @kare = Kare.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products
  # POST /products.json
  def create
    @kare = Kare.new(kare_params)

    respond_to do |format|
      if @kare.save
        format.html { redirect_to @kare, notice: 'Kare was successfully created.' }
        format.json { render :show, status: :created, location: @kare }
      else
        format.html { render :new }
        format.json { render json: @kare.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      if @kare.update(kare_params)
        format.html { redirect_to @kare, notice: 'Kare was successfully updated.' }
        format.json { render :show, status: :ok, location: @kare }
      else
        format.html { render :edit }
        format.json { render json: @kare.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @kare.destroy
    respond_to do |format|
      format.html { redirect_to kares_url, notice: 'Kare was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def import
    Kare.delay.import
    flash[:notice] = 'Задача обновления каталога запущена'
    redirect_to kares_path
  end

  def csv_param
    Kare.delay.csv_param
    flash[:notice] = "Запустили"
    redirect_to kares_path
  end

  private

  def set_kare
    @kare = Kare.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def kare_params
    params.require(:kare).permit(:sku, :title, :full_title, :desc, :cat, :charact, :charact_gab, :oldprice, :price, :quantity, :image, :url)
  end
end
