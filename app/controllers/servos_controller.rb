class ServosController < ApplicationController
  before_action :define_servo, only: %i[show edit update destroy]

  def index
    @servos = Servo.includes(:conjuge, :user).order(:nome)
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
    @servo.assign_attributes(servo_campos_basicos)

    ok = atualizar_servo_e_conta_associada!(
      primeiro_login_pedido: dar_login_solicitado?,
      password: pwd_form,
      password_confirmation: pwd_conf_form
    )

    unless ok
      render :edit, status: :unprocessable_entity
      return
    end

    redirect_to @servo, notice: "Servo atualizado."
  end

  def destroy
    @servo.destroy!
    redirect_to servos_url, notice: "Servo removido."
  end

  private

  def define_servo
    @servo = Servo.includes(:conjuge, :parceiro_conjuge, :user).find(params[:id])
  end

  def servo_raiz_params
    params.require(:servo)
  end

  def servo_campos_basicos
    servo_raiz_params.permit(:nome, :email, :telefone, :sexo, :conjuge_id)
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
      password_confirmation: password_confirmation
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
