# app/values/short_code.rb
# Value Object for Base62 encoding/decoding of short codes
class ShortCode
  include Comparable

  CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze
  MAX_LENGTH = 15

  # Encode a database ID to Base62
  # @param id [Integer] the database ID to encode
  # @return [String] the Base62 encoded short code
  def self.encode(id)
    return CHARS[0] if id.zero?

    result = []
    base = CHARS.length
    while id > 0
      id, remainder = id.divmod(base)
      result.unshift(CHARS[remainder])
    end
    result.join
  end

  # Decode a Base62 short code to database ID
  # @param code [String] the Base62 short code to decode
  # @return [Integer] the database ID
  def self.decode(code)
    return 0 if code.blank?

    base = CHARS.length
    code.reverse.each_char.with_index.sum { |char, i| CHARS.index(char) * (base ** i) }
  end

  # Validate short code format
  # @param code [String] the short code to validate
  # @return [Boolean] true if valid format
  def self.valid_format?(code)
    code.present? &&
      code.length <= MAX_LENGTH &&
      code.match?(/\A[a-zA-Z0-9]+\z/)
  end
end
