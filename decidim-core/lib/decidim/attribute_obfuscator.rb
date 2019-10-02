# frozen_string_literal: true

module Decidim
  class AttributeObfuscator
    def self.email_hint(full_email)
      return nil unless full_email.present? && full_email.include?("@")

      segments = full_email.split("@")
      segment_1 = segments.first
      segment_2 = segments.second

      segment_1 = if segment_1.length < 4
                    "#{segment_1.first}#{'*' * (segment_1.length - 1)}"
                  else
                    "#{segment_1[0..2]}#{'*' * (segment_1.length - 3)}"
                  end
      segment_2 = "#{'*' * (segment_2.length - 3)}#{segment_2[-3..]}"

      "#{segment_1}@#{segment_2}"
    end

    def self.name_hint(name)
      return nil unless name.present?
      return "#{name.first}#{'*' * (name.length - 2)}#{name.last}" unless name.length > 6

      "#{name[0..2]}#{'*' * (name.length - 6)}#{name[-3..]}"
    end

    def self.census_attribute_hint(value)
      value = value.to_s

      return nil unless value.present?
      return value unless value.length > 3

      "#{value.first}#{'*' * (value.length - 4)}#{value[-3..]}"
    end
  end
end
