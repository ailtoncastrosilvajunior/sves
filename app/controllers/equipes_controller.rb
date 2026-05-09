class EquipesController < ApplicationController
  before_action :set_edicao
  before_action :set_equipe, only: %i[show edit update destroy]

  def index
    @equipes = Equipe.order(:nome)
    @membro_count_por_equipe = EquipeServo.where(edicao: @edicao).group(:equipe_id).count(:servo_id)
  end

  def show
    @vinculos = @equipe.equipe_servos
                        .where(edicao: @edicao)
                        .joins(:servo)
                        .includes(:servo)
                        .merge(Servo.order(:nome))

    ocupados_na_equipe = @equipe.servidor_ids_na_edicao(@edicao)
    @servos_disponiveis_para_vinculo =
      Servo
        .where.not(id: ocupados_na_equipe)
        .includes(:conjuge, :parceiro_conjuge)
        .order(:nome)
    @base_voluntarios_vazia = !Servo.exists?
  end

  def new
    @equipe = Equipe.new
  end

  def edit
  end

  def create
    @equipe = Equipe.new(equipe_params)

    if @equipe.save
      redirect_to [@edicao, @equipe], notice: "Equipe criada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @equipe.update(equipe_params)
      redirect_to [@edicao, @equipe], notice: "Equipe atualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @equipe.destroy!
    redirect_to edicao_equipes_path(@edicao), notice: "Equipe removida."
  end

  private

  def set_edicao
    @edicao = Edicao.find(params[:edicao_id])
  end

  def set_equipe
    @equipe = Equipe.find(params[:id])
  end

  def equipe_params
    params.require(:equipe).permit(:nome)
  end
end
