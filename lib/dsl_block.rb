require 'dsl_block/version'
require 'dsl_block/executor'
require 'active_support/core_ext/string/inflections'

# DslBlock is a base class for defining a Domain Specific Language. Subclasses of DslBlock define the desired dsl.
# These methods become available to ruby code running in the context of the subclass.
# The block execution is automatically isolated to prevent the called block from accessing instance methods unless
# specifically designated as callable. DslBlocks can be nested and parent blocks can allow their methods to be exposed to child block.
#
# ==== Example
#    # Define three DslBlocks each with at least one command in each block
#    class Foo < DslBlock
#      commands :show_foo
#      def show_foo(x)
#        "Mr. T says you are a foo times #{x.to_i}"
#      end
#    end
#
#    class Bar < DslBlock
#      commands :show_bar
#      def show_bar(x)
#        "Ordering #{x.to_i} Shirley Temples from the bar"
#      end
#    end
#
#    class Baz < DslBlock
#      commands :show_baz
#      def show_baz(x)
#        "Baz spaz #{x.inspect}"
#      end
#    end
#
#    # Connect the blocks to each other so they can be easily nested
#    Baz.add_command_to(Bar)
#    Bar.add_command_to(Foo, true) # Let Bar blocks also respond to foo methods
#    Foo.add_command_to(self)
#
#    # Use the new DSL
#    foo do
#      self.inspect       # => #<Foo:0x007fdbd52b54e0 @block=#<Proc:0x007fdbd52b5530@/home/fhall/wonderland/alice.rb:29>, @parent=nil>
#      x = 10/10
#      show_foo x         # => Mr. T says you are a foo times 1
#
#      bar do
#        x *= 2
#        show_bar x       # => Ordering 2 Shirley Temples from the bar
#
#        x += 1
#        show_foo x       # => Mr. T says you are a foo times 3
#
#        baz do
#
#          x *= 4
#          x /= 3
#          show_baz x     # => Baz spaz 4
#
#          begin
#            x += 1
#            show_bar x   # => NameError
#          rescue NameError
#            'No bar for us'
#          end
#        end
#
#      end
#
#    end
#
class DslBlock
  # Parent object providing additional commands to the block.
  attr_accessor :parent
  # Block of code that will be executed upon yield.
  attr_accessor :block

  # With no arguments, returns an array of command names that this DslBlock makes available to blocks either directly or indirectly.
  # With arguments, adds new names to the array of command names, then returns the new array.
  def self.commands(*args)
    @commands ||= []
    @commands = (@commands + args.map(&:to_sym)).uniq
    @commands
  end

  # This is a convenience command that allows this DslBlock to inject itself as a method into another DslBlock or Object.
  # If the parent is also a DslBlock, the new method will automatically be added to the available commands.
  #
  # Params:
  # +destination+:: The object to receive the new method
  # +propigate_local_commands+:: Allow methods in the destination to be called by the block. (default: false)
  # +command_name+:: The name of the method to be created or nil to use the default which is based off of the class name. (default: nil)
  def self.add_command_to(destination, propigate_local_commands=false, command_name=nil)
    # Determine the name of the method to create
    command_name = (command_name || name).to_s.underscore.to_sym
    # Save a reference to our self so we will have something to call in a bit when self will refer to someone else.
    this_class = self
    # Define the command in the destination.
    destination.send(:define_method, command_name) do |&block|
      # Create a new instance of our self with the callers 'self' passed in as an optional parent.
      # Immediately after initialization, yield the block.
      this_class.new(propigate_local_commands ? self : nil, &block).yield
    end
    # Add the new command to the parent if it is a DslBlock.
    destination.commands << command_name if destination.is_a?(Class) && destination < DslBlock
  end

  # Create a new DslBlock instance.
  # +parent+:: Optional parent DslBlock or Object that is providing additional commands to the block. (default: nil)
  # +block+:: Required block of code that will be executed when yield is called on the new DslBlock instance.
  def initialize(parent = nil, &block)
    raise ArgumentError, 'block must be provided' unless block_given?
    @block = block
    @parent = parent
  end

  # This is the entire list of commands that this instance makes available to the block of code to be run.
  # It is a combination of three distinct sources.
  # 1. The class's declared commands
  # 2. If there is a parent of this DslBock instance...
  #    * The parents declared commands if it is a DslBlock
  #    * The parents public_methods if it is any other type of object
  # 3. Kernel.methods
  #
  # This method is prefixed with an underscore in an attempt to avoid collisions with commands in the given block.
  def _commands
    cmds = self.class.commands.dup
    if @parent
      if @parent.is_a?(DslBlock)
        cmds += @parent._commands
      else
        cmds +=  @parent.public_methods
      end
    end
    (cmds + Kernel.methods).uniq
  end

  # Yield the block given.
  def yield
    begin
      # Evaluate the block in an executor to provide isolation
      # and prevent accidental interference with ourselves.
      Executor.new(self).instance_eval(&@block)
    rescue Exception => e
      e.set_backtrace(caller.select { |x| !x.include?(__FILE__)})
      raise e
    end
  end

  # :nodoc:
  def respond_to_missing?(method, include_all)
    @parent && @parent.respond_to?(method, include_all) || super
  end

  def method_missing(name, *args, &block)
    if @parent && @parent.respond_to?(name)
      @parent.send(name, *args, &block)
    else
      super
    end
  end
end
