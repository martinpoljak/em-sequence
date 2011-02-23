#!/usr/bin/ruby
# encoding: utf-8
# (c) 2011 Martin Kozák

require 'eventmachine'
require 'hash-utils/hash'

class Foo
    def M1(arg1, &block)
        block.call(1, arg1)
    end
    
    def M2(x, y, &block)
        block.call(x + y)
    end
    
    def M3(z, &block)
        block.call(z ** 2)
    end
end

class EM::Sequence
    @target
    @stack
    @args
    @last
    
    def initialize(target)
        @target = target
        @stack = [ ]
        @args = { }
    end
    
    def method_missing(name, *args, &block)
        @stack << Method::new(@target, name, args, block)
    end
    
    def declare(&block)
        self.instance_eval(&block)
    end
    
    def variable(name, value)
        @args[name] = value
    end
    
    alias :var :variable
    
    def block(*args, &block)
        @stack << Block::new(block, args)
    end
    
    def run(&callback)
        worker = Proc::new do
            if not @stack.empty?
                @stack.shift.call(@args) do |result, returning|
                    @args.merge! result
                    @last = returning
                    
                    EM::next_tick { worker.call() }
                end
            else
                EM::next_tick { callback.call(@last) }
            end
        end
        
        worker.call()
    end
end

class EM::Sequence::Method
    @target
    @name
    @args
    @metablock
    
    def initialize(target, name, args, metablock)
        @target = target
        @name = name
        @args = args
        @metablock = metablock
    end
    
    def call(args, &block)
        call_args = args.values_at(*@args)
        @target.send(@name, *call_args) do |*returns|
            result = Hash::combine(self.meta, returns)
            block.call(result, returns.first)
        end
    end
    
    def meta
        @meta = @metablock.call() \
            if @meta.nil? and (not @metablock.nil?)
        @meta = [@meta] \
            if @meta and (not @meta.kind_of? Array)
        @meta = [ ] \
            if @meta.nil?
        
        return @meta
    end
end

class EM::Sequence::Block
    @body
    @args
    
    def initialize(body, args)
        @body = body
        @args = args
    end
    
    def call(args, &block)
        call_args = args.values_at(*@args)
        result = @body.call(*call_args)
        
        block.call(result, result)
    end
end

EM::run do
    bar = EM::Sequence::new(Foo::new)

    bar.declare do
        variable :arg1, 3
        
        M1(:arg1) { [:x, :y] }
        block(:x, :y) do |x, y|
            {:x => x + 1, :y => y + 1}
        end
        M2(:x, :y) { :x }
        M3(:x)
    end 
    
    bar.run do |result|
        puts result.inspect
    end
end
