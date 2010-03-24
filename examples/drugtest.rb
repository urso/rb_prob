
require 'rubygems'

require 'prob'
include Probably

# same problem as in diagnosis.rb, but with drug users and Test.
# just using some different methods to implement the same queries...

def drugTest(puser = 0.001, p_posifuser = 0.99, p_posifclean = 0.01)
    choose(puser, :User, :Clean).dep { |user|
        choose(if user == :User then p_posifuser else p_posifclean end,
               :Pos, :Neg).dep { |test|
            mk_const([user, test])
        }
    }
end

def drugTest2
    drugTest.dep {|u,t|
        if t == :Pos then mk_const(u) else nil end
    }
end

def drugTest3(puser = 0.001, p_posifuser = 0.99, p_posifclean = 0.01)
    choose(puser, :User, :Clean).dep { |user|
        choose(if user == :User then p_posifuser else p_posifclean end,
               :Pos, :Neg).dep { |test|
            condition(test == :Pos) {
                mk_const user
            }
        }
    }.normalize
end

#p drugTest2

puts "test1"
puts drugTest

puts "\ntest2"
puts drugTest.filter {|u,t| t == :Pos }

puts "\ntest3"
puts drugTest(0.5).filter {|u,t| t == :Pos}

puts "\ntest4"
puts drugTest3

puts "\ntest5"
puts drugTest3(0.5)

