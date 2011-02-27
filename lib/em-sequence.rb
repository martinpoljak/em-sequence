# encoding: utf-8
# (c) 2011 Martin Kozák

require 'eventmachine'
require 'hash-utils/hash'
require 'em-sequence/block'
require 'em-sequence/method'

##
# Main EventMachine module.
# @see http://rubyeventmachine.com/
#

module EM

    ##
    # EventMachine sequence runner.
    #
    
    class Sequence
    
        ##
        # Holds target instance of the sequencer.
        # @return [Object]
        #

        attr_accessor :target
        @target
        
        ##
        # Holds required calls stack. (So in fact sequence itself.)
        # @return [Array]
        #
        
        attr_accessor :stack
        @stack
        
        ##
        # Holds array of variables available and defined during
        # sequence run.
        #
        # @return [Hash]
        #
        
        attr_accessor :vars
        @vars
        
        ##
        # Returns last run sequence item result.
        # @return Object
        #
        
        attr_accessor :last
        @last
        
        ##
        # Constructor.
        # @param [Object] target target instance for the sequence
        #
        
        def initialize(target)
            @target = target
            @stack = [ ]
            @vars = { }
        end
        
        ##
        # Handles method definitions in sequence declaration.
        #
        # @param [Symbol] name method name
        # @param [Array] args input variables specification
        # @param [Proc] block block which should return array of 
        #   returned variables names
        #
        
        def method_missing(name, *args, &block)
            @stack << Method::new(@target, name, args, block)
        end
        
        ##
        # Receives the sequence declaration.
        #
        # @example
        #   bar.declare do
        #
        #       # variable declaration
        #       variable :var, 3
        #
        #       # method call declaration
        #       some_method(:var) { [:x, :y] }
        #
        #       # inline block declaration and definition
        #       block(:x, :y) do |x, y|
        #           {:x => x + 1, :y => y + 1}
        #       end
        #
        #       # some other methods
        #       other_method(:x, :y) { :x }
        #       another_method(:x)
        #
        #   end 
        #
        # @param [Proc] block sequence declaration
        # @return [Sequence] itself
        #
        
        def declare(&block)
            self.instance_eval(&block)
            return self
        end
        
        alias :decl :declare
        
        ##
        # Declares variable.
        #
        # @param [Symbol] name name of the variable
        # @param [Object] value value of the variable
        #
        
        def variable(name, value)
            @vars[name] = value
        end
        
        alias :var :variable
        
        ##
        # Declares block.
        #
        # Given block must return Hash with variable names and values.
        # If block is last item of the sequence, return value will be
        # used as return value of the sequence.
        #
        # @param [Array] args array of arguments
        # @param [Proc] block body of block
        
        def block(*args, &block)
            @stack << Block::new(block, args)
        end
        
        alias :b :block
        alias :blk :block
        
        ##
        # Runs the sequence.
        #
        # @param [Proc] callback callback for giving back result of lat
        #   item of the sequence
        #
        
        def run!(&callback)
            worker = Proc::new do
                if not @stack.empty?
                    @stack.shift.call(@vars) do |result, returning|
                        @vars.merge! result
                        @last = returning
                        
                        EM::next_tick { worker.call() }
                    end
                elsif not callback.nil?
                    EM::next_tick { callback.call(@last) }
                end
            end
            
            worker.call()
        end
        
        ##
        # Declares and runs specified block in one call. Useful if you
        # don't expect any results.
        #
        # @param [Object] target target instance for the sequence
        # @param [Proc] block sequence declaration
        # @see #declare
        # @since 0.1.1
        #
        
        def self.run(target, &block)
            self::new(target).declare(&block).run!
        end
    end
end
