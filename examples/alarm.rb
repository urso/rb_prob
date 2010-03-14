
require '../src/prob'
include Probably

PBulgary = choose(0.001,  :B, :notB )
PEarthquake = choose(0.002,  :E, :notE)

PAlarmTable = {
    [:B, :E] => 0.95,
    [:B, :notE] => 0.94,
    [:notB, :E] => 0.29,
    [:notB, :notE] => 0.001
}

def p_alarm(b, e) 
    choose(PAlarmTable[[b, e]],  :A, :notA)
end

def p_john(a) 
    choose( a == :A ? 0.9 : 0.05, :J, :notJ)
end

def p_mary(a)
    choose( a == :A ? 0.7 : 0.01, :M, :notM)
end

def mk_joint_p(&blk)
    PBulgary.dep { |b|
        PEarthquake.dep {|e|
            p_alarm(b, e).dep {|a|
                p_john(a).dep { |j|
                    p_mary(a).dep {|m|
                        mkState(if blk then blk.call([b,e,a,j,m])
                                else [b,e,a,j,m] end)
                    }
                }
            }
        }
    }
end

def mk_joint_p2( tsts = {}, &blk )
    PBulgary.dep { |b|
    condition(!tsts[:bulgary] || tsts[:bulgary] == b) {
        PEarthquake.dep {|e|
        condition(!tsts[:earthquake] || tsts[:earthquake] == e) {
            p_alarm(b,e).dep {|a|
            condition(!tsts[:alarm] || tsts[:alarm] == a) {
                p_john(a).dep {|j|
                condition(!tsts[:john] || tsts[:john] == j) {
                    p_mary(a).dep {|m|
                    condition(!tsts[:mary] || tsts[:mary] == m) {
                        mkState(if blk then blk.call [b,e,a,j,m] else [b,e,a,j,m] end)
                    }}
                }}
            }}
        }}
    }}.normalize
end

def mk_joint_p3 (tsts = {}, &blk)
    tst_b = ifJust tsts[:bulgary]
    tst_e = ifJust tsts[:earthquake]
    tst_a = ifJust tsts[:alarm]
    tst_j = ifJust tsts[:john]
    tst_m = ifJust tsts[:mary]

    PBulgary.event_dep(tst_b) {|b|
        PEarthquake.event_dep(tst_e) {|e|
            p_alarm(b,e).event_dep(tst_a) {|a|
                p_john(a).event_dep(tst_j) {|j|
                    p_mary(a).event_dep(tst_m) {|m|
                        mkState(if blk then blk.call [b,e,a,j,m] else [b,e,a,j,m] end)
                    }
                }
            }
        }
    }.normalize
end

def mk_test2
    (PBulgary * PEarthquake).dep {|b,e|
        p_alarm(b,e).dep {|a|
            (p_john(a) * p_mary(a)).dep {|j,m|
                condition( e == :notE && j == :J && m == :M && a == :A) {
                    mkState [b,a]
                }
            }
        }
    }
end

def tst_mk_j
    mk_joint_p {|b,e,a,j,m| [j,m] }
end

PJoint = mk_joint_p

#puts PJoint
#puts ""
puts mk_joint_p2({:mary => :M, :john => :J, :earthquake => :notE, :alarm => :A}) { |b,e,a,j,m| b }.query?(&just(:B))
puts mk_joint_p3({:mary => :M, :john => :J, :earthquake => :notE, :alarm => :A}) { |b,e,a,j,m| b }.query?(&just(:B))

puts mk_joint_p.filter {|b,e,a,j,m| e == :notE && j == :J && m == :M && a == :A }.query? {|b,e,a,j,m| b == :B }

require 'benchmark'

Benchmark.bmbm {|x|
    i = 1000
    x.report('joint probability:') {
        (1..i).each {
            mk_joint_p.filter {|b,e,a,j,m| e == :notE && j == :J && m == :M && a == :A }.query? {|b,e,a,j,m| b == :B }
        }
    }

    x.report('direkt:') {
        (1..i).each {
            mk_joint_p {|b,e,a,j,m| 
                if e == :notE && j == :J && m == :M  && a == :A
                    [b,a] 
                else 
                    nil 
                end
            }.query? {|b,a| b == :B}
        }
    }

    x.report('direkt with conditions:') {
        (1..i).each {
            mk_joint_p2({:mary => :M, :john => :J, :earthquake => :notE, :alarm => :A}) { |b,e,a,j,m| b }.query?(&just(:B))
        }
    }

    x.report('direkt with event condition:') {
        (1..i).each {
            mk_joint_p3({:mary => :M, :john => :J, :earthquake => :notE, :alarm => :A}) { |b,e,a,j,m| b }.query?(&just(:B))
        }
    }
}

# 
# p mk_joint_p.filter {|b,e,a,j,m| j == :J}.query? {|b,e,a,j,m| m == :M}
# p tst_mk_j.filter {|j,m| j == :J}.query? {|j,m| m == :M}
# 
# p mk_joint_p.filter {|b,e,a,j,m| e == :notE && j == :J && m == :M && b == :B}.query? { |b,e,a,j,m| a == :A}
# p mk_joint_p {|b,e,a,j,m| if e == :notE && b == :B then [b,e,a,j,m] else nil end}.filter{|b,e,a,j,m| j == :J && m == :M}.query? {|b,e,a,j,m| a == :A}
# 
# p mk_joint_p {|b,e,a,j,m| if e == :notE && j == :J && m == :M then [b,a] else nil end}.filter{|b,a| a == :A}.query? {|b,a| b == :B}
# 
# p mk_joint_p {|b,e,a,j,m| 
#     if e == :notE && j == :J && m == :M
#         [b,a] 
#     else 
#         nil 
#     end
# }.filter {|b,a| a == :A }.query? {|b,a| b == :B}
# 
