# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# Pluralização de models em português (Rails usa locale :en ao derivar nomes).
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "edicao", "edicoes"
  inflect.irregular "servo", "servos"
  inflect.irregular "equipe", "equipes"
  inflect.irregular "cenaculo", "cenaculos"
  inflect.irregular "casal", "casais"
end

ActiveSupport::Inflector.inflections(:pt) do |inflect|
  inflect.irregular "edicao", "edicoes"
  inflect.irregular "servo", "servos"
  inflect.irregular "equipe", "equipes"
  inflect.irregular "cenaculo", "cenaculos"
  inflect.irregular "casal", "casais"
end
