# Servo enquanto pastor neste cenáculo (pastor de cenáculo).
class CenaculoServo < ApplicationRecord
  self.table_name = "cenaculo_servos"

  belongs_to :cenaculo
  belongs_to :servo

  validates :servo_id, uniqueness: { scope: :cenaculo_id }
end
