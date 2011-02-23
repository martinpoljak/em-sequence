# encoding: utf-8
# (c) 2011 Martin Kozák

##
# Main EventMachine module.
# @see
#

module EM
    
    ##
    # EventMachine sequence runner.
    #
    
    class Sequence
    
        ##
        # Block caller sequence item.
        #
    
        class Block
        
            ##
            # Holds body of the block.
            # @return [Proc]
            #
            
            attr_accessor :body
            @body
        
            ##
            # Input variables specification.
            # @return [Array]
            #
            
            attr_accessor :args
            @args

            ##
            # Constructor.
            #
            # @param [Proc] body body of the block
            # @param [Array] args input variables specification
            #
                        
            def initialize(body, args)
                @body = body
                @args = args
            end
            
            ##
            # Calls the block.
            #
            # @param [Hash] vars data hash with current variables state
            # @param [Proc] block block for giving back the call result
            #
            
            def call(vars, &block)
                call_args = vars.values_at(*@args)
                result = @body.call(*call_args)
                block.call(result, result)
            end
        end
    end
end
