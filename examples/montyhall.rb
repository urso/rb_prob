
require '../src/prob'
include Probably

$doors = [:A, :B, :C]

# state is hashmap with keys:
# :open     => door opened by entertainer
# :prize    => door the prize is behind
# :selected => by player selected door

$testWinner = proc do |s|
    if s[:prize] == s[:selected]
        :Winner
    else
        :Looser
    end
end

def winnerProb(prob)
    check = proc do |s|
        if s[:prize] == s[:selected]
            :Winner
        else
            :Looser
        end
    end

    prob.map $testWinner
end

def stay(prob)
    prob
end

def switch(prob)
    prob.dep do |s|
        s_ = ($doors - [s[:selected], s[:open]]).map do |d|
            {:open => s[:open], :selected => d, :prize => s[:prize]}
        end
        uniform s_
    end
end

hide   = uniform( $doors.map { |d| {:prize => d} }   )
choose = uniform( $doors.map { |d| {:selected => d}} )

hideThenChoose = hide.mult(choose) { |p,s|
    {:prize => p[:prize], :selected => s[:selected]}
}

#p hideThenChoose

opened = hideThenChoose.dep do |s|
    s_ = ($doors - [s[:prize], s[:selected]]).map do |d|
        {:open => d, :prize => s[:prize], :selected => s[:selected]}
    end
    uniform s_
end
#p opened

p winnerProb(stay(opened))
p winnerProb(switch(opened)).most_probable


