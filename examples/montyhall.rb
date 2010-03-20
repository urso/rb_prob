
require 'rubygems'

require 'prob'
include Probably

# the monty hall problem is a simple game show based probability puzzle with
# a puzzling outcome :)
#
# Suppose you are on a game show and you are given the choice of 3 doors.
# Behind one of these doors is the price and behind the others a goat. Only the
# moderator knows behind which door the price is and will open one door with a
# goat after you did your first choice. Next you can choose if you want to
# switch doors or not.
#
# Question:
# What is the best strategie? Stay or switch?
# What are the probabilities of winning for each of these strategies?
#

# first we want to encode our state.
#
# these are the doors one can choose from: 
$doors = [:A, :B, :C]

# state final state is hashmap with keys:
# :open     => door opened by entertainer
# :prize    => door the prize is behind
# :selected => by player selected door

# testing function on state to find out if we win or loose
$testWinner = proc do |s|
    if s[:prize] == s[:selected]
        :Winner
    else
        :Looser
    end
end

# apply event function $testWinner on 
# each possible state
def winnerProb(prob)
    prob.map &$testWinner
end

# Let us encode the problem with random variables:
#
# P  = doors : door prize was put behind
# C1 = doors : the door chosen in the first round by player
# O  = doors :  the door opened by show's host
#

# first step: let's hide the price
# P(P = A) = 1/3
# P(P = B) = 1/3
# P(P = C) = 1/3
hide   = uniform( $doors.map { |d| {:prize => d} }   )

# and then let the player choose one door:
# P(C1 = A) = 1/3
# P(C1 = B) = 1/3
# P(C1 = C) = 1/3
choose = uniform( $doors.map { |d| {:selected => d}} )

# combine event P and C1 and create state representation:
# P(C1|P) = P(C1) * P(P)     <- because event P and C1 are independent
hideThenChoose = hide.mult(choose) { |p,s|
    {:prize => p[:prize], :selected => s[:selected]}
}

# compute probability distribution of host opening a specific door
# given the event P and C1:
# P(O|C1,P)
# with O != C1 and O != P
opened = hideThenChoose.dep do |s|
    s_ = ($doors - [s[:prize], s[:selected]]).map do |d|
        {:open => d, :prize => s[:prize], :selected => s[:selected]}
    end
    uniform s_
end
#p opened

# finally implement strategie 'stay'
def stay(prob)
    prob
end

# and strategy 'switch' choosing a door C2 with
# C2 != O and C2 != C1.
# find P(C2|O, C1, P)
def switch(prob)
    prob.dep do |s|
        s_ = ($doors - [s[:selected], s[:open]]).map do |d|
            {:open => s[:open], :selected => d, :prize => s[:prize]}
        end
        uniform s_
    end
end

# print some results
puts 'if stay most probable result: ', winnerProb(stay(opened)).most_probable
puts 'if switch most probable result: ', winnerProb(switch(opened)).most_probable
puts ''
puts 'if stay porbability of winning: ', winnerProb(stay(opened)).probability(:Winner)
puts 'if switch porbability of winning: ', winnerProb(switch(opened)).probability(:Winner)

