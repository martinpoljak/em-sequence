#!/usr/bin/ruby
# encoding: utf-8
# (c) 2011 Martin Kozák

$:.push("./lib")

require 'eventmachine'
require 'em-sequence'
require 'riot'

test = nil


class Calculator
    def some_method(var, &block)
        block.call(1, var)
    end

    def other_method(x, y, &block)
        block.call(x + y)
    end

    def another_method(z, &block)
        block.call(z ** 2)
    end
end

EM::run do
    EM::Sequence::new(Calculator::new).declare {
        # variable declaration
        variable :var, 3

        # method call declaration
        some_method(:var) { [:x, :y] }              #   | TICK 1
                                                    #   V
        # inline block declaration and definition
        block(:x, :y) do |x, y|                     #   | TICK 2
            {:x => x + 1, :y => y + 1}              #   |
        end                                         #   V

        # some other methods
        other_method(:x, :y) { :x }                 #   V TICK 3
        another_method(:x)                          #   V TICK 4
    }.run! do |result|
        test = result
        EM::stop
    end
end

context "Sequencer" do
    setup { test }
    asserts("complex sequence") { topic == 36 }
end
