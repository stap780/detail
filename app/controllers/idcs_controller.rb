class IdcsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_idc, only: [:show, :edit, :update, :destroy, :pars_one]

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
    @search = Idc.ransack(new_q)
    @search.sorts = 'id desc' if @search.sorts.empty?
    @idcs = @search.result.paginate(page: params[:page], per_page: 100)
    # if params['otchet_type'] == 'selected'
    #   Idc.csv_param_selected( params['selected_idcs'], params['otchet_type'])
    #   new_file = "#{Rails.public_path}"+'/ins_detail_selected.csv'
    #   send_file new_file, :disposition => 'attachment'
    # end
  end

  def show; end

  def new
    @idc = Idc.new
  end

  def edit; end

  def create
    @idc = Idc.new(idc_params)

    respond_to do |format|
      if @idc.save
        format.html { redirect_to idcs_url, notice: 'Product was successfully created.' }
        format.json { render :show, status: :created, location: @idc }
      else
        format.html { render :new }
        format.json { render json: @idc.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @idc.update(idc_params)
        format.html { redirect_to idcs_url, notice: 'Product was successfully updated.' }
        format.json { render :show, status: :ok, location: @idc }
      else
        format.html { render :edit }
        format.json { render json: @idc.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @idc.destroy
    respond_to do |format|
      format.html { redirect_to idcs_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
      flash.now[:success] = 'Product was successfully destroyed.'
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@idc),
          render_turbo_flash
        ]
      end
    end
  end

  # def edit_multiple
  #   if params[:idc_ids].present?
  #     @idcs = Idc.find(params[:idc_ids])
  #     respond_to do |format|
  #       format.turbo_stream
  #     end
  #   else
  #     respond_to do |format|
  #       format.html { redirect_to idcs_url, notice: 'select idcs' }
  #       format.json { head :no_content }
  #       flash.now[:success] = 'select idcs'
  #       format.turbo_stream do
  #         render turbo_stream: [
  #           render_turbo_flash
  #         ]
  #       end
  #     end
  #   end
  # end

  # def update_multiple
  #   @idcs = Idc.find(params[:idc_ids])
  #   @idcs.each do |pr|
  #     attr = params[:idc_attr]
  #     attr.each do |key,value|
  #       next if key.to_s == 'picture'

	# 			if key.to_s != 'picture'
	# 				if !value.blank?
	# 				  pr.update_attributes(key => value)
  #           Idc.update_pricepr(pr.id) if key.to_s == 'pricepr'
	# 				end
	# 			end
	# 		end
	# 	end
	# 	flash[:notice] = 'Данные обновлены'
	# 	redirect_to :back
  # end

  def bulk_export
    if params[:idc_ids].present?
      respond_to do |format|
        format.html { redirect_to idcs_url, notice: 'Product print' }
        format.json { head :no_content }
        flash.now[:success] = 'Product print.'
        format.turbo_stream
      end
      idcs = Idc.where(id: params[:idc_ids].split(','))
      Idc.csv_param_selected(idcs, 'selected')
    else
      respond_to do |format|
        format.html { redirect_to idcs_url, notice: 'select idcs' }
        format.json { head :no_content }
        flash.now[:success] = 'select idcs'
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    end
  end

  def delete_selected
    if params[:idc_ids].present?
      idcs = Idc.where(id: params[:idc_ids].split(','))
      idcs.each do |idc|
        idc.destroy
      end
      respond_to do |format|
        format.html { redirect_to idcs_url, notice:  t('success') }
        format.json { head :no_content }
        flash.now[:success] = t('success')
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to idcs_url, notice: 'select idcs' }
        format.json { head :no_content }
        flash.now[:success] = 'select idcs'
        format.turbo_stream do
          render turbo_stream: [
            render_turbo_flash
          ]
        end
      end
    end
  end

  def import
    IdcImportJob.perform_later
    respond_to do |format|
      format.html { redirect_to idcs_url, notice: 'Задача обновления каталога запущена' }
      format.json { head :no_content }
      flash.now[:success] = 'Задача обновления каталога запущена'
      format.turbo_stream do
        render turbo_stream: [
          render_turbo_flash
        ]
      end
    end
  end

  def pars_one
    if @idc.url.present?
      Idc::ParsUrl.call(@idc.url)
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
    IdcCsvParamJob.perform_later
    respond_to do |format|
      format.html { redirect_to idcs_url, notice: 'Запустили' }
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

  def set_idc
    @idc = Idc.find(params[:id])
  end

  def idc_params
    params.require(:idc).permit(:status, :sku, :title, :desc, :cat, :charact, :charact_gab, :oldprice, :price, :quantity, :image, :url, :archived)
  end
end
