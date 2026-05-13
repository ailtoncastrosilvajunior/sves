# frozen_string_literal: true

# Registos Active Storage válidos mas o objecto já não existe no bucket (mudança de serviço, bucket novo,
# cópia de BD sem ficheiros, etc.) faziam os pedidos `/rails/active_storage/...` devolver 500 —
# especialmente Representations quando o original falta no Space.
module ActiveStorageRescueMissingBlob
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveStorage::FileNotFoundError do |_exception|
      head :not_found
    end

    if defined?(ActiveStorage::IntegrityError)
      rescue_from ActiveStorage::IntegrityError do |_exception|
        head :not_found
      end
    end
  end
end

Rails.application.config.to_prepare do
  next unless defined?(ActiveStorage::BaseController)

  mod = ActiveStorageRescueMissingBlob
  ctl = ActiveStorage::BaseController
  ctl.include mod unless ctl.ancestors.include?(mod)
end
