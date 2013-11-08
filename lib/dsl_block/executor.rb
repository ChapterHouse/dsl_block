class DslBlock

  class Executor < BasicObject

    def initialize(dsl_block)
      @dsl_block = dsl_block
    end

    def method_missing(method, *args, &block)
      if @dsl_block._commands.include?(method)
        begin
          @dsl_block.send(method, *args, &block)
        rescue => e
          e.set_backtrace(::Kernel.caller.select { |x| !x.include?(__FILE__)})
          ::Kernel.raise e
        end
      else
        name_error = ::NameError.new("undefined local variable or method `#{method}' for #{self.inspect}")
        name_error.set_backtrace(::Kernel.caller.select { |x| !x.include?(__FILE__)})
        ::Kernel::raise name_error
      end
    end

  end

end
