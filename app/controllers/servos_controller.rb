class ServosController < ApplicationController
  before_action :define_servo, only: %i[show edit update destroy liberar_acesso redefinir_senha_participante]
  before_action :negar_se_nao_coordenacao!, except: %i[show edit update]
  before_action :garantir_servo_apenas_proprio_ou_coordenacao!, only: %i[show edit update]

  def index
    @servos = Servo.includes(:conjuge, :user).order(:nome)
    @servos_aguardando_acesso = Servo.aguardando_acesso_ao_painel.includes(:conjuge, :user).order(:nome)
  end

  def show
  end

  def new
    @servo = Servo.new
  end

  def edit
  end

  def create
    @servo = Servo.new(servo_campos_basicos)

    ok =
      if dar_login_solicitado?
        criar_servo_com_login_opcional!(pwd_form, pwd_conf_form)
      else
        @servo.save
      end

    unless ok
      render :new, status: :unprocessable_entity
      return
    end

    redirect_to @servo, notice: "Servo criado."
  end

  def update
    if pode_gerir_painel?
      @servo.assign_attributes(servo_campos_basicos)
      ok = atualizar_servo_e_conta_associada!(
        primeiro_login_pedido: dar_login_solicitado?,
        password: pwd_form,
        password_confirmation: pwd_conf_form,
      )
    else
      @servo.assign_attributes(servo_campos_somente_nome)
      ok = @servo.save
    end

    unless ok
      render :edit, status: :unprocessable_entity
      return
    end

    redirect_to @servo, notice: (pode_gerir_painel? ? "Servo atualizado." : t("servos.nome_atualizado"))
  end

  def destroy
    @servo.destroy!
    redirect_to servos_url, notice: "Servo removido."
  end

  def liberar_acesso
    pwd = ENV["SVES_SEED_SERVO_PASSWORD"].presence
    unless pwd
      redirect_to @servo, alert: I18n.t("servos.liberar_sem_senha_env")
      return
    end

    if @servo.liberar_acesso_senha_padrao!(pwd)
      redirect_to @servo, notice: I18n.t("servos.liberar_sucesso")
    else
      redirect_to @servo, alert: @servo.errors.full_messages.to_sentence.presence || I18n.t("servos.liberar_falhou")
    end
  end

  def redefinir_senha_participante
    pwd = ENV["SVES_SEED_SERVO_PASSWORD"].presence
    unless pwd
      redirect_to @servo, alert: I18n.t("servos.liberar_sem_senha_env")
      return
    end

    if @servo.coordenacao_redefinir_senha_padrao_participante!(pwd)
      redirect_to @servo, notice: I18n.t("servos.redefinir_sucesso")
    else
      redirect_to @servo, alert: @servo.errors.full_messages.to_sentence.presence || I18n.t("servos.redefinir_falhou")
    end
  end

  def liberar_acesso_lote
    pwd = ENV["SVES_SEED_SERVO_PASSWORD"].presence
    unless pwd
      redirect_to servos_path, alert: I18n.t("servos.liberar_sem_senha_env")
      return
    end

    ids = Array(params[:servo_ids]).map(&:presence).compact.map(&:to_i).uniq
    if ids.empty?
      redirect_to servos_path, alert: I18n.t("servos.liberar_lote_nenhum")
      return
    end

    servos = Servo.where(id: ids)
    ok = 0
    falhas = []

    servos.each do |servo|
      if servo.liberar_acesso_senha_padrao!(pwd)
        ok += 1
      else
        falhas << "#{servo.nome}: #{servo.errors.full_messages.to_sentence}"
      end
    end

    flash[:notice] = I18n.t("servos.liberar_lote_ok", count: ok) if ok.positive?
    flash[:alert] = I18n.t("servos.liberar_lote_falhas", detalhes: falhas.join(" · ")) if falhas.any?
    redirect_to servos_path
  end

  private

  def define_servo
    @servo = Servo.includes(:conjuge, :parceiro_conjuge, :user).find(params[:id])
  end

  def servo_raiz_params
    params.require(:servo)
  end

  def servo_campos_basicos
    servo_raiz_params.permit(:nome, :email, :telefone, :sexo, :conjuge_id, :papel)
  end

  def servo_campos_somente_nome
    servo_raiz_params.permit(:nome)
  end

  def dar_login_solicitado?
    ActiveModel::Type::Boolean.new.cast(servo_raiz_params[:dar_acesso])
  end

  def pwd_form
    servo_raiz_params.permit(:password)[:password]
  end

  def pwd_conf_form
    servo_raiz_params.permit(:password_confirmation)[:password_confirmation]
  end

  def criar_servo_com_login_opcional!(password, password_confirmation)
    if password.blank?
      @servo.errors.add(:password, I18n.t("servos.senha_obrigatoria_com_acesso"))
      return false
    end

    if @servo.email.blank?
      @servo.errors.add(:email, I18n.t("servos.acesso_precisa_email"))
      return false
    end

    user = User.new(
      email: User.normalize_email(@servo.email),
      password: password,
      password_confirmation: password_confirmation,
      must_change_password: true
    )

    sucesso = false
    Servo.transaction do
      unless user.save
        copiar_erros_para(@servo, user)
        raise ActiveRecord::Rollback
      end

      @servo.user_id = user.id

      unless @servo.save
        raise ActiveRecord::Rollback
      end

      sucesso = true
    end

    sucesso
  end

  def atualizar_servo_e_conta_associada!(primeiro_login_pedido:, password:, password_confirmation:)
    if primeiro_login_pedido && @servo.user.blank?
      return criar_servo_com_login_opcional!(password, password_confirmation)
    end

    if password.present? && @servo.user.blank?
      @servo.errors.add(:base, I18n.t("servos.definir_senha_sem_conta"))
      return false
    end

    sucesso = false
    Servo.transaction do
      user = @servo.user

      if user
        novo_email = User.normalize_email(@servo.email.to_s)
        if novo_email.present? && novo_email != user.email
          if User.where(email: novo_email).where.not(id: user.id).exists?
            @servo.errors.add(:email, I18n.t("servos.email_ja_associado_conta"))
            raise ActiveRecord::Rollback
          end
          user.email = novo_email
          user.save!
        end
      end

      if password.present?
        user.password = password
        user.password_confirmation = password_confirmation
        unless user.save
          copiar_erros_para(@servo, user)
          raise ActiveRecord::Rollback
        end
      end

      @servo.save!
      sucesso = true
    end

    sucesso
  rescue ActiveRecord::RecordInvalid
    false
  end

  def copiar_erros_para(destino, origem)
    origem.errors.each do |erro|
      destino.errors.add(erro.attribute, erro.message)
    end
  end
end
