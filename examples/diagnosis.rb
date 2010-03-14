
require '../src/prob'
include Probably

# compute the probability of being ill or health for a test result
# given prior knowledge:
# Suppose T = test result and I = {Ill, Healthy} =>
#
# P(I|T) = < P(T|I) * P(I) >
#

PFalseNegative = 0.01
PFalsePositive = 0.01

# P(I)
PDisease = choose 0.001, :ILL, :HEALTHY

# P(T|I)
PTest = PDisease.dep {|d|
    choose(d == :ILL ? PFalseNegative : 1 - PFalsePositive,
           :Negative, :Positive).dep { |t|
        mkState([d,t])
    }
}

testpred = Proc.new {|disease, test| disease == :ILL}

p PTest

# P(I = Ill | T = Positive)
p "probability of bein ILL if test is Positive:"
p PTest.filter{|disease, test| test == :Positive}.query? &testpred

