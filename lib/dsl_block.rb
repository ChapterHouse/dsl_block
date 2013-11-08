require 'dsl_block/version'
require 'dsl_block/executor'
require 'active_support/core_ext/string/inflections'

class DslBlock
  attr_accessor :parent, :block

  def self.commands(*args)
    @commands ||= []
    @commands = (@commands + args.map(&:to_sym)).uniq
    @commands
  end

  def self.add_command_to(destination, propigate_local_commands=false, command_name=nil)
    command_name = (command_name || name).to_s.underscore.to_sym
    this_class = self
    destination.send(:define_method, command_name) { |&block| this_class.new(propigate_local_commands ? self : nil, &block).yield }
    destination.commands << command_name if destination.is_a?(Class) && destination < DslBlock
  end

  def initialize(parent = nil, &block)
    raise ArgumentError, 'block must be provided' unless block_given?
    @block = block
    @parent = parent
  end

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

  def yield
    begin
      Executor.new(self).instance_eval(&@block)
    rescue Exception => e
      e.set_backtrace(caller.select { |x| !x.include?(__FILE__)})
      raise e
    end
  end

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
