
require 'rubygems'

gem 'rb_prob'; require 'prob'
include Probably

# 
# Problem: 
# Given a positive or negative test for a specific illness we wan't to know the
# probability for being ill or healthy.
#
# Suppose the random variables I and T are given with I = {Ill, Healthy}
# being the health status and T = {Negative, Positive} the test result.
#
# It is known that the probability of being ill is 1 in a 1000,
# thus:
# P(I = Ill) = 0.001 and P(I = Healthy) = 0.999
#
# Furthermore we do know that the test has an accuracy of 99%, thus
# P(T = Positive | I = Ill ) = 0.99
# P(T = Negative | I = Ill ) = 0.01
# P(T = Positive | I = Healthy ) = 0.01
# P(T = Negative | I = Healthy ) = 0.99
#
# Task:
# compute the probability of being ill, given a test was positive.
# Using bayes rule:
#
# P(T, I) = P(T|I) * P(I) = P(I|T) * P(T)
#
# =>
#
#           P(T |I) * P(I)
# P(I|T) = ---------------- = < P(T|I) * P(I) >
#                P(T)
#
#

PFalseNegative = 0.01 # constant for P( T | I = Ill)
PFalsePositive = 0.01 # constant for P( T | I = Healthy)

# define: P(I)
PDisease = choose 0.001, :ILL, :HEALTHY

# P(T|I)
def pTest(i)
    choose(i == :ILL ? PFalseNegative : 1 - PFalsePositive,
           :Negative, :Positive)
end


# P(T|I)
# but combine states and save final distribution in constant
PTest = PDisease.dep {|i|
    pTest(i).dep {|t| mkState([i,t]) }
}

testpred = Proc.new {|disease, test| disease == :ILL}

p PTest

# using filter we find on PTest which is P(T|I) we find 
# P( I | T = Positive )
p "probability of I if test is Positive:"
p PTest.filter{|disease, test| test == :Positive}

# using the testpred function and query we can find the probability of all
# events testpred returns true for. In this case P( I = Ill | T = Positive)
p "probability of being ill"
p PTest.filter{|disease,test| test == :Positive}.query? &testpred

# next find the most probable explanation if Test was Positive:
p "most probable"
p PTest.filter{|disease,test| test == :Positive}.most_probable

# alternatively using condition on the monadic computation directly
# and normalizing the result needed multiplications and memory may be reduced:
# event_dep is like 'dep {|var| condition(var == :Positive) { ... } }'
p "another way of finding P(I|T=Positive)"
p PDisease.dep {|i|
    # event_dep will execute block only if
    # Test was :Positive and return 'nil' else
    pTest(i).event_dep(just :Positive) { 
        mkState(i)
    }
  }.normalize

