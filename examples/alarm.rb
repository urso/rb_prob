
require 'rubygems'

require 'prob'
include Probably

# Alarm example from "Artificial Intelligence - A Modern Approach" by Russel
# and Norvig Page 493 cc.
#
# Suppose you have a new fairly reliable burglar alarm at home but occasionally
# it responds to minor earthquakes. You also have two neighbors John and Mary,
# who have promised to call you at work when they hear the alarm. John always
# calls when he hears the alarm, but sometimes confuses the telephone ringing
# with the alarm and calls then, too. Mary, on the other hand, is too much in
# loud music and sometimes misses the alarm altogether.
#
# So the bayesian network will be:
#
#           B         E
#            \       /
#            _\|   |/_
#                A
#             /    \
#           |/_    _\|
#          J          M
#
#  with probabilities:
#  P(B) = 0.001
#  P(E) = 0.002
#
#  P(A| B=true, E=true)   = 0.95
#  P(A| B=true, E=false)  = 0.94
#  P(A| B=false, E=true)  = 0.29
#  P(A| B=false, E=false) = 0.001
#
#  P(J| A=true)  = 0.9
#  P(J| A=false) = 0.05
#
#  P(M| A=true)  = 0.7 
#  P(M| A=false) = 0.01
#
#  where B = burglar, E = earthquake, A = alarm, J = John calls and 
#  M = Mary calls
#
#  ----------------------------------------------------------------------------
#
#  Next we want to develop some 'equivalent' functions for querying that
#  network and do some benchmarks.
#

# first let's encode the probabilities from the network
# P(B)
PBurglary = choose(0.001,  :B, :notB )

# P(A)
PEarthquake = choose(0.002,  :E, :notE)

# P(A|B = b,E = e)
def p_alarm(b, e) 
    pAlarmTable = {
        [:B, :E] => 0.95,
        [:B, :notE] => 0.94,
        [:notB, :E] => 0.29,
        [:notB, :notE] => 0.001
    }

    choose(pAlarmTable[[b, e]],  :A, :notA)
end

# P(J|A = a)
def p_john(a) 
    choose( a == :A ? 0.9 : 0.05, :J, :notJ)
end

# P(M|A = a)
def p_mary(a)
    choose( a == :A ? 0.7 : 0.01, :M, :notM)
end

# computes the joint probability and transform result using block (if given)
# allowing to do some marginalization over one random variable by 
# "leaving it out"
#
# for example:
# mk_joint_p {|b,e,a,j,m| [b,e,a]} will find P(b,e,a) = Sum(j,m) { P(b,e,a,j,m) }
#
def mk_joint_p(&blk)
    PBurglary.dep { |b|
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

# compute (optionally conditional) joint probability of (free) random
# variables like mk_joint_p.
#
# To compute conditional probability set random variables to a known state.
# for example
# mk_joint_p2( {:john = :J, :mary = :M} ) 
# will compute
# P(B,E,A| J = true, M = true)
#
# or 
# mk_joint_p2({:john = :J, :mary = :M}) {|b,e,a,j,m| b} will find
# P(B | J = true, M = true)
def mk_joint_p2( tsts = {}, &blk )
    PBurglary.dep { |b|
    condition(!tsts[:burglary] || tsts[:burglary] == b) {
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

# like mk_joint_p2, but using event_dep directly instead of mixing in
# condition-statements
def mk_joint_p3 (tsts = {}, &blk)
    tst_b = ifJust tsts[:burglary]
    tst_e = ifJust tsts[:earthquake]
    tst_a = ifJust tsts[:alarm]
    tst_j = ifJust tsts[:john]
    tst_m = ifJust tsts[:mary]

    PBurglary.event_dep(tst_b) {|b|
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

# precompute joint probability to do bayesian inference using filter, map and
# query?
PJoint = mk_joint_p

puts 'P(B|M=true, J=true) :'
puts mk_joint_p3({:mary => :M, :john => :J}) {|b,e,a,j,m| b }

# puts "\njoint probability:"
# puts "=================="
# puts PJoint

# compute P(B | M=true, J=true, E=false, A=true) using all 3 different
# functions mk_joint_p, mk_joint_p2 and mk_joint_p3:
puts "\nP(B | M=true, J=true, E=false, A=true)"
puts "====================================="
puts mk_joint_p2({:mary => :M, :john => :J, :earthquake => :notE, :alarm => :A}) { |b,e,a,j,m| b }.query?(&just(:B))
puts mk_joint_p3({:mary => :M, :john => :J, :earthquake => :notE, :alarm => :A}) { |b,e,a,j,m| b }.probability(:B)
puts PJoint.filter {|b,e,a,j,m| e == :notE && j == :J && m == :M && a == :A }.query? {|b,e,a,j,m| b == :B }

# do some benchmarking:

require 'benchmark'

Benchmark.bmbm {|x|
    i = 1000
    x.report('joint probability:') {
        (1..i).each {
            mk_joint_p.filter {|b,e,a,j,m| e == :notE && j == :J && m == :M && a == :A }.query? {|b,e,a,j,m| b == :B }
        }
    }

    x.report('joint probability precomputed:') {
        (1..i).each {
            PJoint.filter {|b,e,a,j,m| e == :notE && j == :J && m == :M && a == :A}.query? {|b,e,a,j,m| b == :B}
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

# I'm too lazy now to write an interpretation of benchmarking, 
# but I guess you can make up your mind yourself... 
# In short: it's always a trade of between space/time usage and macruby must
# improve floating point...
#
# my results (on unibody MacBook 2GHz with snow leopard):
#
# ===========================================================================
#
# $ ruby -version
# ruby 1.8.7 (2008-08-11 patchlevel 72) [universal-darwin10.0]
#
# Rehearsal ------------------------------------------------------------------
# joint probability:               3.080000   0.190000   3.270000 (  3.273073)
# joint probability precomputed:   0.170000   0.000000   0.170000 (  0.171786)
# direkt:                          2.450000   0.180000   2.630000 (  2.638515)
# direkt with conditions:          0.780000   0.050000   0.830000 (  0.829055)
# direkt with event condition:     0.960000   0.070000   1.030000 (  1.024606)
#--------------------------------------------------------- total: 7.930000sec
#
#                                     user     system      total        real
# joint probability:               3.010000   0.110000   3.120000 (  3.132044)
# joint probability precomputed:   0.170000   0.000000   0.170000 (  0.165960)
# direkt:                          2.470000   0.150000   2.620000 (  2.634326)
# direkt with conditions:          0.770000   0.050000   0.820000 (  0.810167)
# direkt with event condition:     0.930000   0.050000   0.980000 (  0.995371)
#
# ===========================================================================
#
# $ jruby -version
# jruby 1.4.0 (ruby 1.8.7 patchlevel 174) (2009-11-02 69fbfa3) (Java HotSpot(TM) 64-Bit Server VM 1.6.0_17) [x86_64-java]
#
# Rehearsal ------------------------------------------------------------------
# joint probability:               3.100000   0.000000   3.100000 (  3.100000)
# joint probability precomputed:   0.148000   0.000000   0.148000 (  0.148000)
# direkt:                          0.988000   0.000000   0.988000 (  0.988000)
# direkt with conditions:          0.424000   0.000000   0.424000 (  0.424000)
# direkt with event condition:     0.558000   0.000000   0.558000 (  0.558000)
# --------------------------------------------------------- total: 5.217999sec
#
#                                      user     system      total        real
# joint probability:               0.992000   0.000000   0.992000    0.992000
# joint probability precomputed:   0.087000   0.000000   0.087000    0.087000
# direkt:                          0.621000   0.000000   0.621000    0.621000
# direkt with conditions:          0.321000   0.000000   0.321000    0.321000
# direkt with event condition:     0.327000   0.000000   0.327000    0.327000
#
# ===========================================================================
#
# $ macruby -version
# MacRuby version 0.5 (ruby 1.9.0) [universal-darwin10.0, x86_64]
#
# Rehearsal ------------------------------------------------------------------
# joint probability:               7.710000   0.220000   7.930000 (  6.988403)
# joint probability precomputed:   0.140000   0.000000   0.140000 (  0.135137)
# direkt:                          5.550000   0.170000   5.720000 (  5.117666)
# direkt with conditions:          1.740000   0.060000   1.800000 (  1.490908)
# direkt with event condition:     1.750000   0.060000   1.810000 (  1.526937)
# -------------------------------------------------------- total: 17.400000sec
#
#                                      user     system      total        real
# joint probability:               7.610000   0.230000   7.840000    6.693219
# joint probability precomputed:   0.120000   0.010000   0.130000    0.118537
# direkt:                          5.600000   0.190000   5.790000    4.846050
# direkt with conditions:          1.720000   0.070000   1.790000    1.484840
# direkt with event condition:     1.750000   0.060000   1.810000    1.507850
#
