class DslBlock
  # 1.0.0
  VERSION = '1.0.0'

  module Version # :nodoc: all
    MAJOR, MINOR, PATCH, *OTHER = VERSION.split('.')
    NUMBERS = [MAJOR, MINOR, PATCH, *OTHER]
  end

end
