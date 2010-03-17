
require 'rubygems'

gem 'rb_prob'; require 'prob'
include Probably

def drugTest(puser = 0.001, p_posifuser = 0.99, p_posifclean = 0.01)
    choose(puser, :User, :Clean).dep { |user|
        choose(if user == :User then p_posifuser else p_posifclean end,
               :Pos, :Neg).dep { |test|
            mkState([user, test])
        }
    }
end

def drugTest2
    drugTest.dep {|u,t|
        if t == :Pos then mkState(u) else nil end
    }
end

def drugTest3(puser = 0.001, p_posifuser = 0.99, p_posifclean = 0.01)
    choose(puser, :User, :Clean).dep { |user|
        choose(if user == :User then p_posifuser else p_posifclean end,
               :Pos, :Neg).dep { |test|
            condition(test == :Pos) {
                mkState user
            }
        }
    }.normalize
end

#p drugTest2

p drugTest
p drugTest.filter {|u,t| t == :Pos }
p drugTest(0.5).filter {|u,t| t == :Pos}

p drugTest3
# p drugTest3(0.5)

