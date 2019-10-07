# frozen_string_literal: true

module Decidim
  class AttributeObfuscator
    def self.email_hint(full_email)
      return nil unless full_email.present? && full_email.include?("@")

      segments = full_email.split("@")
      local_part = segments.first

      obfuscated_local_part = if local_part.length < 3
                                obfuscate(0, 0, local_part)
                              elsif local_part.length < 6
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

      return nil if name.blank?
      return obfuscate(0, 0, name) if name.length < 3
      return obfuscate(1, 1, name) if name.length < 5

      obfuscate(3, 3, name)
    end

    # This is the default obfuscator for the authorizations log, so
    # let's be conservative with obfuscation
    def self.secret_attribute_hint(value)
      value = value.to_s

      return nil if value.blank?
      return "*" * value.length if value.length < 5

      "#{value.first}#{"*" * (value.length - 2)}#{value.last}"
    end

    def self.obfuscate(plain_start_size, plan_end_size, value)
      obfuscated_length = value.length - plain_start_size - plan_end_size

      plain_start = plain_start_size.zero? ? "" : value[0..plain_start_size - 1]
      obfuscated = "*" * obfuscated_length
      plain_end = plan_end_size.zero? ? "" : value[-plan_end_size..value.length]

      "#{plain_start}#{obfuscated}#{plain_end}"
    end
    private_class_method :obfuscate
  end
end
