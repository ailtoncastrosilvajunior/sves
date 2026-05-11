Edicao.find_or_create_by!(ano: 2026, numero_edicao: 1) do |e|
  e.link_planilha = nil
  e.ativa = true
end

unless Edicao.em_curso.exists?
  Edicao.order(ano: :desc, numero_edicao: :desc).first&.update!(ativa: true)
end

if ENV["SVES_ADMIN_PASSWORD"].present?
  mail = User.normalize_email(ENV.fetch("SVES_ADMIN_EMAIL", "coordenacao@sves.local"))
  user = User.find_or_initialize_by(email: mail)
  user.admin = true

  unless user.persisted?
    user.password = ENV["SVES_ADMIN_PASSWORD"]
    user.password_confirmation = ENV["SVES_ADMIN_PASSWORD"]
    user.must_change_password = true
  end

  user.save!
end

# Ligado aos servos: cria conta de acesso (User) para quem já tem e-mail no cadastro e ainda não tem user_id.
# senha por defeito para desenvolvimento / primeiro arranque; em produção defina SVES_SEED_SERVO_PASSWORD.
pwd_servos = ENV.fetch("SVES_SEED_SERVO_PASSWORD", "sves2026.1")

lista_servos = [
  { email: "ailton@swind.com.br", nome: "Ailton", sexo: "M" },
  { email: "liliane-resende@bol.com.br", nome: "Liliane", sexo: "F" },
  { email: "simon@waysustentabilidade.com", nome: "Simon", sexo: "M" },
  { email: "gildasiollneto@gmail.com", nome: "Gildásio Neto", sexo: "M" },
  { email: "marcio@swind.com.br", nome: "Márcio", sexo: "M" }
]

lista_servos.each do |dados|
  Servo.find_or_create_by!(email: dados[:email]) do |s|
    s.nome = dados[:nome]
    s.sexo = dados[:sexo]
    s.origem_cadastro = Servo::ORIGEM_IMPORTACAO
    s.papel = Servo::PAPEL_COORDENACAO
  end
end

Servo.where(user_id: nil).where.not(email: nil).find_each do |servo|
  email = User.normalize_email(servo.email)
  next if email.blank?

  begin
    utilizador_existente = User.find_by(email: email)

    if utilizador_existente
      if utilizador_existente.servo.present? && utilizador_existente.servo.id != servo.id
        puts "[seed] Servo #{servo.id}: e-mail #{email} já ligado ao servo #{utilizador_existente.servo.id}; omitido."

        next
      end

      if utilizador_existente.servo.nil?
        servo.update!(user: utilizador_existente)
        puts "[seed] Servo #{servo.id}: ligado ao utilizador já existente #{email}."
      end
      next
    end

    ActiveRecord::Base.transaction do
      u = User.create!(
        email: email,
        password: pwd_servos,
        password_confirmation: pwd_servos,
        must_change_password: true
      )
      servo.update!(user: u)
    end
    puts "[seed] Servo #{servo.id}: criado utilizador para #{email}."
  rescue ActiveRecord::RecordInvalid => e
    puts "[seed] Servo #{servo.id}: #{e.record.errors.full_messages.to_sentence}"
  end
end
