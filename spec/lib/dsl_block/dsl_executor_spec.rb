require 'spec_helper'

describe DslBlock::Executor do

  context '.new' do

    it 'inherits from BasicObject to constrain the block' do
      expect(DslBlock::Executor.superclass).to equal(BasicObject)
    end

  end

  context '#method_missing' do

    it 'calls the method on the dsl_block if it contains the method in its #_commands' do
      dsl_block = Object.new
      dsl_block.stub(:foo).and_return('bar')
      dsl_block.stub(:_commands).and_return([:foo, :inspect])
      executor = DslBlock::Executor.new(dsl_block)
      expect(executor.foo).to eql('bar')
    end

    it 'raises NameError if the dsl_block does not contain the method in its #_commands' do
      dsl_block = Object.new
      dsl_block.stub(:foo).and_return('bar')
      dsl_block.stub(:_commands).and_return([:inspect])
      executor = DslBlock::Executor.new(dsl_block)
      expect { executor.bar }.to raise_error(NameError)
    end

  end

  context 'any exception' do

    it 'removes itself from the backtrace to make it easier to understand' do
      begin
        dsl_block = Object.new
        dsl_block.stub(:_commands).and_return([:inspect])
        executor = DslBlock::Executor.new(dsl_block)
        executor.bar
      rescue => e
        expect(e.backtrace.any? { |x| x.include?('dsl_block/lib/dsl_block/executor.rb')} ).to be_false
      end

      begin
        dsl_block = Object.new
        dsl_block.stub(:foo) { raise 'Kaboom' }
        dsl_block.stub(:_commands).and_return([:inspect, :foo])
        executor = DslBlock::Executor.new(dsl_block)
        executor.foo
      rescue => e
        expect(e.message).to eql('Kaboom')
        expect(e.backtrace.any? { |x| x.include?('dsl_block/lib/dsl_block/executor.rb')} ).to be_false
      end

    end

  end


end