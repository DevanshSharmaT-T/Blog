# frozen_string_literal: true

class TemplatesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index, :show ]
  before_action :set_template, only: [ :show, :edit, :update, :destroy ]

  def index
    @templates = Template.active.order(:name)
  end

  def show; end

  def new
    authorize! :create, Template
    @template = Template.new
  end

  def create
    authorize! :create, Template
    @template = Template.new(template_params)
    @template.created_by_id = current_user.id

    if @template.save
      redirect_to templates_path, notice: "Template created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! :update, @template
  end

  def update
    authorize! :update, @template
    if @template.update(template_params)
      redirect_to templates_path, notice: "Template updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! :destroy, @template
    @template.update!(is_active: false)
    redirect_to templates_path, notice: "Template archived."
  end

  private

  def set_template
    @template = Template.find_by!(slug: params[:id])
  end

  def template_params
    permitted = params.require(:template).permit(
      :name, :slug, :description, :thumbnail_url, :preview_url,
      :category, :is_premium, :is_active, :layout_config_raw
    )

    raw = permitted.delete(:layout_config_raw)
    if raw.present?
      begin
        permitted[:layout_config] = JSON.parse(raw)
      rescue JSON::ParserError
        permitted[:layout_config] = { "raw" => raw }
      end
    end
    permitted
  end
end
