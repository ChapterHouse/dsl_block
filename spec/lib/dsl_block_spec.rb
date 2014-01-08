require 'spec_helper'

describe DslBlock do

  before(:each) do
    dsl_reset
  end

  context '.commands' do

    it 'starts as an empty array' do
      expect(dsl_class1.commands).to eql([])
    end

    it 'accepts multiple method names' do
      dsl_class1.commands :a, :b, :c
      expect(dsl_class1.commands).to eql([:a, :b, :c])
    end

    it 'appends the method names to the existing list' do
      dsl_class1.commands :a, :b, :c
      dsl_class1.commands :d, :e, :f
      expect(dsl_class1.commands).to eql([:a, :b, :c, :d, :e, :f])
    end

    it 'returns the current method names when setting' do
      expect(dsl_class1.commands(*[:a, :b, :c])).to eql([:a, :b, :c])
      expect(dsl_class1.commands(*[:d, :e, :f])).to eql([:a, :b, :c, :d, :e, :f])
    end

    it 'removes duplicates' do
      dsl_class1.commands :a, :b, :a
      dsl_class1.commands :c, :b, :d
      expect(dsl_class1.commands).to eql([:a, :b, :c, :d])
    end

  end

  context '.add_command_to' do

    it 'defines a method in the destination' do
      dsl_class2.add_command_to(dsl_class1)
      expect(dsl_class1.instance_methods.include?(dsl_class2_command)).to be_true
    end

    it 'allows for the name of the method to be chosen' do
      dsl_class2.add_command_to(dsl_class1, :command_name => :foo)
      expect(dsl_class1.instance_methods.include?(:foo)).to be_true
    end

    it 'adds to the commands in the destination if it is a DslBlock' do
      dsl_class2.add_command_to(dsl_class1)
      expect(dsl_class1.commands.include?(dsl_class2_command)).to be_true
    end

    it 'allows a non DslBlock destination' do
      generic_class = Class.new
      dsl_class2.add_command_to(generic_class)
      expect(generic_class.instance_methods.include?(dsl_class2_command)).to be_true
    end

    context 'the method created' do

      it 'creates a new instance of the target' do
        dsl_class2.should_receive(:new).and_call_original
        dsl12 {}
      end

      it 'calls the block given' do
        expect(dsl12 { 1 }).to equal(1)
      end

      it 'executes the block in the context of the target' do
        expect(dsl12 { self }).to be_instance_of(dsl_class2)
      end

    end

    context 'propagate_commands' do

      it 'by default is false and does not propagate parent block commands' do
        dsl_class1.send(:define_method, :foo) { |x| 'foo' * x }
        dsl_class1.commands :foo

        dsl = dsl12(false) { foo(2) }

        expect { dsl.yield }.to raise_error(NameError)
        # Prove we can call it normally
        expect( dsl.foo(1)).to eql('foo')
      end

      it 'can be true to propagate parent block commands' do
        dsl_class1.send(:define_method, :foo) { |x| 'foo' * x }
        dsl_class1.commands :foo

        dsl = dsl12(false, true) { foo(2) }

        expect(dsl.yield).to eql('foofoo')
        # Prove we can call it normally
        expect(dsl.foo(1)).to eql('foo')
      end

      it 'will not propagate parent block commands that aren\'t marked as commands' do
        dsl_class1.send(:define_method, :foo) { |x| 'foo' * x }
        # Unlike above, :foo will not added to the list of commands at this point.

        dsl = dsl12(false) { foo(2) }

        expect { dsl.yield }.to raise_error(NameError)
        # Prove we can call it normally
        expect(dsl.foo(1)).to eql('foo')
      end

    end

  end


  context '.new' do

    it 'requires a block' do
      expect{dsl_class1.new}.to raise_error(ArgumentError, 'block must be provided')
    end

    it 'accepts the block in the options hash' do
      block = Proc.new {}
      expect{dsl_class1.new(:block => block) }.to_not raise_error
    end

    it 'stores the block for later execution' do
      block = Proc.new {}
      dsl = dsl_class1.new(&block)
      expect(dsl.instance_variable_get(:@block)).to equal(block)
    end

    it 'uses regular block over options block' do
      block1 = Proc.new {}
      block2 = Proc.new {}
      dsl = dsl_class1.new(:block => block1, &block2)
      expect(dsl.instance_variable_get(:@block)).to equal(block2)
    end

    it 'can also take a parent object' do
      object = Object.new
      dsl = dsl_class1.new(:parent => object) {}
      expect(dsl.instance_variable_get(:@parent)).to equal(object)
    end

  end

  context '#_commands' do

    context 'without a parent object' do

      it 'shows only the dsl class commands and the Kernel.methods available to the block passed' do
        dsl_class1.commands :foo, :bar
        dsl = dsl1(false) {}
        expect(dsl._commands.sort).to eql((dsl_class1.commands + Kernel.methods).uniq.sort)
      end

    end

    context 'with a DslBlock parent' do

      it 'shows the dls class commands, the parent._commands, and the Kernel.methods available to the block passed' do
        dsl_class2.send(:define_method, :true_self) { self }
        dsl_class2.commands :true_self
        dsl_class1.commands :foo, :bar
        dsl2_instance = dsl12(true, true) { true_self }

        expect(dsl2_instance._commands.sort).to eql((dsl_class1.commands + dsl_class2.commands + Kernel.methods).sort)
      end

    end

    context 'with a generic Object parent' do

      it 'shows the dls class commands, the object.public_methods, and the Kernel.methods available to the block passed' do
        array = Array.new
        dsl1_instance = dsl_class1.new(:parent => array) {}
        expect(dsl1_instance._commands.sort).to eql((Kernel.methods + dsl_class1.commands + array.public_methods).sort.uniq)
      end

    end

  end

  context '#yield' do

    it 'yields the block given at instantiation' do
      dsl = dsl_class1.new { 3 }
      expect(dsl.yield).to equal(3)
    end

    it 'creates an executor to evaluate the block' do
      dsl = dsl_class1.new {}
      DslBlock::Executor.should_receive(:new).with(dsl).and_call_original
      dsl.yield
    end

    it 'isolates the block by evaluating it in the context of the executor' do
      block = Proc.new {}
      dsl = dsl_class1.new(&block)
      executor = DslBlock::Executor.new(dsl)
      executor.should_receive(:instance_eval).with(&block)
      DslBlock::Executor.stub(:new).and_return(executor)
      dsl.yield
    end

    it 'cleans up any backtraces by removing itself from the call stack' do
      begin
        dsl123 { raise 'Kaboom' }
      rescue => e
        expect(e.message).to eql('Kaboom')
        expect(e.backtrace.any? { |x| x.include?('dsl_block/lib/dsl_block.rb')} ).to be_false
      end
    end
  end

  context '#respond_to_missing?' do

    it 'behaves as normal if no parent is set' do
      dsl = dsl_class1.new {}
      expect(dsl.respond_to?(:each)).to equal(false)
      expect(dsl.respond_to?(:to_s)).to equal(true)
    end

    it 'also checks with the parent if it is set' do
      dsl = dsl_class1.new(:parent => Array.new) {}
      expect(dsl.respond_to?(:each)).to equal(true)
      expect(dsl.respond_to?(:to_s)).to equal(true)
    end

  end

  context '#method_missing?' do

    it 'behaves as normal if no parent is set' do
      dsl = dsl_class1.new {}
      expect { dsl.each }.to raise_error(NoMethodError)
    end

    it 'relays the call to the parent if it is set' do
      dsl = dsl_class1.new(:parent => Array.new) {}
      expect { dsl.each }.not_to raise_error
    end

  end

end

