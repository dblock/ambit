# This gem allows choose/fail (amb) style non-deterministic programming in
# Ruby
#
# Author::    Jim Wise  (mailto:jwise@draga.com)
# Copyright:: Copyright (c) 2011 Jim Wise
# License::   2-clause BSD-Style (see LICENSE[link:files/LICENSE.html])

module Nondeterminism

  VERSION = '0.9.0'

  # A ChoicesExhausted exception is raised if the outermost choose invocation of
  # a Generator has run out of choices, indicating that no (more) solutions are possible
  class ChoicesExhausted < StandardError
  end

  class Generator
    def initialize
      @paths = []
    end

    # Clear all outstanding choices registered with this generator.
    #
    # Returns the generator to the state it was in before all choices were
    # made.  Does not affect control flow.
    def clear!
      @paths = []
    end

    # Given an enumerator, begin a generate-and-test process.
    #
    # Returns with the first member of the enumerator.  A later call to #fail!
    # on the same generator will backtrack and try the next value in the
    # enumerator, continuing from the point of this #choose as if that value
    # had been chosen originally.
    #
    # Multiple calls to #choose will nest, so that backtracking forms
    # a tree-like execution path
    #
    # calling #choose with no argument or an empty iterator 
    # is equivalent to calling #fail!
    def choose choices = []
      ch = choices.clone          # clone it in case it's modified by the caller
      ch.each do |choice|
        callcc do |cc|
          @paths.unshift cc
          return choice
        end
      end
      self.fail!                  # if we get here, we've exhausted the choices
    end

    alias amb choose

    # Indicate that the current combination of choices has failed, and roll execution back
    # to the last #choose, continuing with the next choice.
    def fail!
      raise ChoicesExhausted.new if @paths.empty?
      cc = @paths.shift
      # if it quacks (or can be called) like a duck, call it -- it's either a Proc from #mark or a Continuation from #choose
      cc.call
    end

    def require cond
      fail! unless cond
    end

    alias assert require

    def mark 
      @paths.unshift Proc.new {self.fail!}
    end

    def cut!
      return if @paths.empty?
      # rewind paths back to the last mark
      @paths = @paths.drop_while {|x| x.instance_of? Continuation}
      # drop up to one mark
      @paths = @paths.drop(1) unless @paths.empty?
    end
  end

  def Nondeterminism::method_missing(sym, *args, &block) # :nodoc:
    Nondeterminism::Default_Generator.send(sym, *args, &block);
  end

  # The default generator used by ND.choose, ND.fail!, et al.
  # should not be used directly.
  Default_Generator = Generator.new # :nodoc:

end

# For convenience, ND is an alias for the NonDeterminism module
ND = Nondeterminism # :nodoc: