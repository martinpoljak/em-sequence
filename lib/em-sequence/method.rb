# encoding: utf-8
# (c) 2011 Martin Kozák

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
        # Method caller sequence item.
        #
    
        class Method
        
            ##
            # Holds method target object.
            # @return [Object]
            #
            
            attr_accessor :target
            @target
            
            ##
            # Holds method name.
            # @return [Symbol]
            #
            
            attr_accessor :name
            @name
            
            ##
            # Input variables specification.
            # @return [Array]
            #
            
            attr_accessor :args
            @args
            
            ##
            # Block which returns returned variables specification.
            # @return [Proc]
            #
            
            attr_accessor :metablock
            @metablock
            
            ##
            # Constructor.
            #
            # @param [Object] target target (parent) object instance of the call
            # @param [Symbol] name method name
            # @param [Array] args input variables specification
            # @param [Proc] metablock returning variables specification block
            #
            
            def initialize(target, name, args, metablock)
                @target = target
                @name = name
                @args = args
                @metablock = metablock
            end
            
            ##
            # Calls the method.
            #
            # @param [Hash] vars data hash with current variables state
            # @param [Proc] block block for giving back the call result
            #
            
            def call(vars, &block)
                call_args = vars.values_at(*@args)
                @target.send(@name, *call_args) do |*returns|
                    result = Hash::combine(self.meta, returns)
                    block.call(result, returns.first)
                end
            end
            
            
            protected
            
            ##
            # Returns returned values metainformations from metablock.
            #
            
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
    end
end

