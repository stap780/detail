class KaresController < ApplicationController

  before_action :authenticate_user!
  before_action :set_kare, only: [:show, :edit, :update, :destroy, :pars_one]

  def index
    @search = Kare.ransack(params[:q])
    @search.sorts = 'id asc' if @search.sorts.empty?
    @kares = @search.result.paginate(page: params[:page], per_page: 50)
    # if params['otchet_type'] == 'selected'
    #   Product.csv_param_selected( params['selected_products'], params['otchet_type'])
    #   new_file = "#{Rails.public_path}"+'/kare_selected.csv'
    #   send_file new_file, :disposition => 'attachment'
    # end
  end

  def bulk_export
    if params[:kare_ids].present?
      kares = Kare.where(id: params[:kare_ids].split(','))
      Kare.csv_param_selected(kares, 'selected')
      respond_to do |format|
        format.html { redirect_to kares_url, notice: 'Kares print' }
        format.json { head :no_content }
        flash.now[:success] = 'Kares print.'
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to kares_url, notice: 'select kares' }
        format.json { head :no_content }
        flash.now[:success] = 'select kares'
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    end
  end

  def delete_selected    
    if params[:kare_ids].present?
      kares = Kare.where(id: params[:kare_ids].split(','))
      kares.each do |kare|
        kare.destroy
      end
      respond_to do |format|
        format.html { redirect_to kares_url, notice: 'Kares was successfully destroyed.' }
        format.json { head :no_content }
        flash.now[:success] = 'Kares was successfully destroyed.'
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to kares_url, notice: 'select kares' }
        format.json { head :no_content }
        flash.now[:success] = 'select kares'
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    end
  end

  def show
  end

  def new
    @kare = Kare.new
  end

  def edit
  end

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

  def update
    respond_to do |format|
      if @kare.update(kare_params)
        format.html { redirect_to kares_url, notice: 'Kare was successfully updated.' }
        format.json { render :show, status: :ok, location: @kare }
      else
        format.html { render :edit }
        format.json { render json: @kare.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @kare.destroy
    respond_to do |format|
      format.html { redirect_to kares_url, notice: 'Kare was successfully destroyed.' }
      format.json { head :no_content }
      flash.now[:success] = 'Kare was successfully destroyed.'
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@kare),
          render_turbo_flash
        ]
      end
    end
  end


  def pars
    KareCollectLinksJob.perform_later
    respond_to do |format|
      format.html { redirect_to kares_url, notice: 'Запустили' }
      format.json { head :no_content }
      flash.now[:success] = 'Запустили'
      format.turbo_stream do
        render turbo_stream: [
          render_turbo_flash
        ]
      end
    end
  end

  def pars_one
    if @kare.url.present?
      KareParsPage.new(@kare.url).call
      respond_to do |format|
        flash.now[:success] = 'Обновили информацию'
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    else
      respond_to do |format|
        flash.now[:success] = 'нет ссылки в в позиции'
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    end
  end

  def csv_param
    # Rails.env.development? ? Kare.csv_param : Kare.delay.csv_param
    # flash[:notice] = "Запустили"
    # redirect_to kares_path
    kares = Kare.all.finished
    Kare.csv_param_selected(kares, 'full')
    respond_to do |format|
      format.html { redirect_to kares_url, notice: 'Запустили' }
      format.json { head :no_content }
      format.turbo_stream
      # flash.now[:success] = 'Запустили'
      # format.turbo_stream do
      #   render turbo_stream: [
      #     render_turbo_flash
      #   ]
      # end
    end
  end

  private

  def set_kare
    @kare = Kare.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def kare_params
    params.require(:kare).permit(:status, :sku, :title, :full_title, :desc, :cat, :charact, :charact_gab, :oldprice, :price, :quantity, :image, :url)
  end
end
