class EquipesServosController < ApplicationController
  before_action :set_edicao
  before_action :negar_se_nao_coordenacao!
  before_action :set_equipe

  def create
    @equipe_servo = @equipe.equipe_servos.build(equipe_servo_params.merge(edicao: @edicao))
    servo_id_alvo = @equipe_servo.servo_id
    unless servo_id_alvo.present? && Servo.where(id: servo_id_alvo).exists?
      redirect_to edicao_equipe_path(@edicao, @equipe),
                  alert: "Escolha um servo válido."
      return
    end

    if @equipe_servo.save
      redirect_to edicao_equipe_path(@edicao, @equipe), notice: "Servo adicionado à equipe."
    else
      redirect_to edicao_equipe_path(@edicao, @equipe),
                  alert: @equipe_servo.errors.full_messages.to_sentence.presence || "Não foi possível adicionar o servo."
    end
  end

  # Aceita vários servos («principais») de uma só vez: servidor_principal_ids ou (legado) servidor_principal_id.
  # Cada principal expande pelo casal quando aplicável; duplicados e quem já está na edição ficam de fora.
  def lote
    forma_raw = params.require(:forma).to_s

    unless %w[coordenacao participante].include?(forma_raw)
      redirect_to edicao_equipe_path(@edicao, @equipe), alert: "Papel inválido."
      return
    end

    ordered_principal_ids =
      servidor_principal_ids_ordenados_unicos(
        ids_string: params[:servidor_principal_ids],
        fallback_id: params[:servidor_principal_id],
      )

    if ordered_principal_ids.empty?
      redirect_to edicao_equipe_path(@edicao, @equipe), alert: "Seleccione pelo menos um servo."
      return
    end

    encontrados_por_id = Servo.where(id: ordered_principal_ids).includes(:conjuge, :parceiro_conjuge).index_by(&:id)
    if encontrados_por_id.size != ordered_principal_ids.uniq.size
      redirect_to edicao_equipe_path(@edicao, @equipe), alert: "Um ou mais servos não foram encontrados."
      return
    end

    servos_por_id = encontrados_por_id
    ordem_servos_objetos = ordered_principal_ids.filter_map { |id| servos_por_id[id] }

    ids_ja_na_equipe = @equipe.servidor_ids_na_edicao(@edicao).to_set
    servidor_ids_ordem_para_criar = []

    ordem_servos_objetos.each do |servo|
      ids_casal = Servo.ids_do_casal_incluindo(servo)
      na_base_ids = Servo.where(id: ids_casal).pluck(:id).to_set
      unless ids_casal.all? { |sid| na_base_ids.include?(sid) }
        redirect_to edicao_equipe_path(@edicao, @equipe),
                    alert: "Só são aceites servos cadastrados na base — se vier casal em conjunto, associe primeiro o perfil dos dois antes de repetir esta ação."
        return
      end

      novos_para_este_principal = ids_casal.reject { |sid| ids_ja_na_equipe.include?(sid) }
      novos_para_este_principal.each do |sid|
        next if servidor_ids_ordem_para_criar.include?(sid)

        servidor_ids_ordem_para_criar << sid
        ids_ja_na_equipe.add(sid)
      end
    end

    if servidor_ids_ordem_para_criar.empty?
      redirect_to edicao_equipe_path(@edicao, @equipe),
                  alert: "Quem você selecionou (e eventual cônjuge) já está nesta equipe."
      return
    end

    nomes = []
    ActiveRecord::Base.transaction do
      servidor_ids_ordem_para_criar.each do |sid|
        es = @equipe.equipe_servos.create!(servo_id: sid, forma: forma_raw, edicao: @edicao)
        nomes << es.servo.nome
      end
    end

    notice =
      case nomes.length
      when 1 then "#{nomes.first} adicionado(a) à equipe."
      when 2 then "#{nomes[0]} e #{nomes[1]} adicionados à equipe."
      else "#{nomes[0...-1].join(', ')} e #{nomes.last} adicionados à equipe."
      end

    redirect_to edicao_equipe_path(@edicao, @equipe), notice: notice
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edicao_equipe_path(@edicao, @equipe),
                alert: e.record.errors.full_messages.to_sentence.presence || "Não foi possível concluir a adição."
  end

  def destroy
    @equipe_servo = @equipe.equipe_servos.where(edicao_id: @edicao.id).find(params[:id])
    @equipe_servo.destroy!
    redirect_to edicao_equipe_path(@edicao, @equipe), notice: "Servo retirado da equipe."
  end

  private

  def set_edicao
    @edicao = Edicao.find(params[:edicao_id])
  end

  def set_equipe
    @equipe = Equipe.find(params[:equipe_id])
  end

  def equipe_servo_params
    params.require(EquipeServo.model_name.param_key).permit(:servo_id, :forma)
  end

  # Lista de ids inteiros (ordem clicada; sem repetir entrada).
  def servidor_principal_ids_ordenados_unicos(ids_string:, fallback_id:)
    tokens =
      begin
        s = ids_string.to_s.strip
        if s.present?
          s.split(/[\s,;]+/).map(&:strip).reject(&:blank?)
        elsif fallback_id.present?
          [fallback_id.to_s.strip]
        else
          []
        end
      end

    unique_ints_ordered = []

    tokens.each do |tok|
      n = tok.to_i
      next unless n.positive?

      unique_ints_ordered << n unless unique_ints_ordered.include?(n)
    end

    unique_ints_ordered
  end
end
