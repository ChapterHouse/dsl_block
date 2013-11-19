class DslBlock

  # The Executor class is designed to run a block of code in isolation
  # for the DslBlock class. By running it in a 'sandbox', the block
  # of code cannot inadvertently access protected and private methods
  # within the DslBlock without explicate declaration by the DslBlock.
  # To the user, it will appear that the block runs directly in the
  # DslBlock but in a partly restricted manner if they care to investigate.
  # In this fashion, executor is effectively a transparent proxy.
  class Executor < BasicObject

    def initialize(dsl_block)
      @dsl_block = dsl_block
    end

    def method_missing(method, *args, &block)
      # If the dsl block lists the method as a callable command
      if @dsl_block._commands.include?(method)
        # Attempt to call it
        begin
          @dsl_block.send(method, *args, &block)
        rescue => e
          # If there is any type of error, remove ourselves from the callstack to reduce confusion.
          e.set_backtrace(::Kernel.caller.select { |x| !x.include?(__FILE__)})
          ::Kernel.raise e
        end
      else
        # Otherwise raise a no method error as if the method does not really exist, regardless of reality.
        name_error = ::NameError.new("undefined local variable or method `#{method}' for #{self.inspect}")
        name_error.set_backtrace(::Kernel.caller.select { |x| !x.include?(__FILE__)})
        ::Kernel::raise name_error
      end
    end

  end

end
