# frozen_string_literal: true

module Decidim
  class AttributeObfuscator
    def self.email_hint(full_email)
      return nil unless full_email.present? && full_email.include?("@")

      segments = full_email.split("@")
      local_part = segments.first

      obfuscated_local_part = if local_part.length < 6
                                obfuscate(1, 1, local_part)
                              elsif local_part.length < 10
                                obfuscate(2, 2, local_part)
                              else
                                obfuscate(3, 3, local_part)
                              end

      "#{obfuscated_local_part}@#{segments.second}"
    end

    def self.name_hint(name)
      name = name.to_s

      return nil unless name.present?
      return obfuscate(1, 1, name) if name.length < 5

      obfuscate(3, 3, name)
    end

    # This is the default obfuscator for the authorizations log, so
    # let's be conservative with obfuscation
    def self.secret_attribute_hint(value)
      value = value.to_s

      return nil unless value.present?
      return "#{'*' * value.length}" if value.length < 5

      "#{value.first}#{'*' * (value.length - 2)}#{value.last}"
    end

    def self.obfuscate(plain_beggining_length, plan_ending_length, value)
      obfuscated_length = value.length - plain_beggining_length - plan_ending_length

      "#{value[0..plain_beggining_length - 1]}#{'*' * obfuscated_length}#{value[-plan_ending_length..]}"
    end
    private_class_method :obfuscate
  end
end
