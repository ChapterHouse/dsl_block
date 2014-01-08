require 'simplecov'
SimpleCov.start('test_frameworks')
require 'rspec/autorun'
require 'dsl_block'

RSpec.configure do |config|
  config.order = 'random'
end

# Due to the nature of these tests, the number of discreete classes involved, and scoping issues
# the memoizaton will occur here instead of the standard rspec 'let' statements. Feel free to
# move these back to standard let statements if the specs can be kept as clean or cleaner


# Generic dsl class. Used in the specs as the outermost block
def dsl_class1
  @dsl_class1||= Class.new(DslBlock).tap do |klass|
    def klass.name
      'Dsl1'
    end
  end
end

# Generic dsl class. Used in the specs as the middle block
def dsl_class2
  @dsl_class2 ||= Class.new(DslBlock).tap do |klass|
    def klass.name
      'Dsl2'
    end
  end
end

# Generic dsl class. Used in the specs as the innermst block
def dsl_class3
  @dsl_class3 ||= Class.new(DslBlock).tap do |klass|
    def klass.name
      'Dsl3'
    end
  end
end

# The command the outermost dsl block is usually called by
def dsl_class1_command
  dsl_class1.name.underscore.to_sym
end

# The command the middle dsl block is usually called by
def dsl_class2_command
  dsl_class2.name.underscore.to_sym
end

# The command the innermost dsl block is usually called by
def dsl_class3_command
  dsl_class3.name.underscore.to_sym
end

# Reset all of the classes for a new test
def dsl_reset
  @dsl_class1 = nil
  @dsl_class2 = nil
  @dsl_class3 = nil
end




# The following are helpers to DRY up the tests.
# The numbers after 'dsl' are references to the order the dsl blocks are nested.


# No nested dsl. Block given is run at the ellipsis
# dsl_class1 do
#   ...
# end
def dsl1(auto_yield=true, &block)
  dsl = dsl_class1.new(&block)
  auto_yield ? dsl.yield : dsl
end

# Nested dsl. Block given is run at the ellipsis
# dsl_class1 do
#   dsl_class2 do
#     ...
#   end
# end
def dsl12(auto_yield=true, propagate12=false, &block)
  dsl_class2.add_command_to(dsl_class1, :propagate => propagate12)
  command = dsl_class2_command
  dsl = dsl_class1.new do
    self.send(command, &block)
  end
  auto_yield ? dsl.yield : dsl
end

# Double nested dsl. Block given is run at the ellipsis
# dsl_class1 do
#   dsl_class2 do
#     dsl_class3 do
#       ...
#     end
#   end
# end
def dsl123(auto_yield=true, propagate12=false, propagate23=false, &block)
  dsl_class2.add_command_to(dsl_class1, :propagate => propagate12)
  dsl_class3.add_command_to(dsl_class2, :propagate => propagate23)
  command2 = dsl_class2_command
  command3 = dsl_class3_command
  dsl = dsl_class1.new do
    self.send(command2) do
      self.send(command3, &block)
    end
  end
  auto_yield ? dsl.yield : dsl
end
