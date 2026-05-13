# frozen_string_literal: true

# Credenciais e região do Spaces são fáceis de errar: NoSuchBucket com bucket bem escrito é quase sempre datacenter≠DO_SPACES_REGION.
Rails.application.config.after_initialize do
  svc_sym = Rails.application.config.active_storage.service
  next unless svc_sym == :digitalocean_spaces

  keys = %w[DO_SPACES_BUCKET DO_SPACES_ACCESS_KEY_ID DO_SPACES_SECRET_ACCESS_KEY]
  missing = keys.select { |k| ENV[k].to_s.strip.empty? }
  if missing.any?
    Rails.logger.warn(
      "[active_storage] Serviço digitalocean_spaces sem variáveis: #{missing.join(', ')} — uploads remoto falham até corrigir.",
    )
    next
  end

  dc = ENV["DO_SPACES_REGION"].to_s.strip
  Rails.logger.warn(
    '[active_storage] DO_SPACES_REGION não definida no ambiente — o storage.yml assume "nyc3" para montar ' \
    "DO_SPACES_ENDPOINT. Se Space estiver doutro datacenter aparece Aws::S3::Errors::NoSuchBucket mesmo com nome de bucket correcto.",
  ) if dc.blank?

  s3_svc = ActiveStorage::Blob.services.fetch(:digitalocean_spaces)
  cli = s3_svc.client.respond_to?(:client) ? s3_svc.client.client : nil # Aws::S3::Client
  Rails.logger.info(
    "[active_storage] Spaces: bucket=#{s3_svc.bucket.name.inspect} endpoint=#{cli&.config&.endpoint} assinatura_region=#{cli&.config&.region}",
  )
rescue StandardError => e
  Rails.logger.warn("[active_storage] inicialização Spaces (#{Rails.application.config.active_storage.service}): #{e.class}: #{e.message}")
end
