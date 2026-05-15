# frozen_string_literal: true

module EquipesHelper
  # Agrupa registos EquipeServo quando o cônjuge também está na mesma lista (uma linha por casal).
  # Quem entra sem par na equipe fica sozinho num grupo de um elemento.
  def equipe_vinculos_agrupados_por_casal(vinculos)
    list = vinculos.to_a
    return [] if list.empty?

    ids_no_conjunto = list.map(&:servo_id).to_set
    consumidos = Set.new
    grupos = []

    list.sort_by { |v| v.servo.nome.to_s.downcase }.each do |v|
      next if consumidos.include?(v.servo_id)

      parceiro_id = v.servo.conjuge_id.presence || v.servo.parceiro_conjuge&.id
      if parceiro_id && ids_no_conjunto.include?(parceiro_id)
        v_par = list.find { |x| x.servo_id == parceiro_id }
        if v_par
          consumidos.add(v.servo_id)
          consumidos.add(parceiro_id)
          dupla = [v, v_par].sort_by { |x| x.servo.nome.to_s.downcase }
          grupos << dupla
          next
        end
      end

      consumidos.add(v.servo_id)
      grupos << [v]
    end

    grupos
  end
end
