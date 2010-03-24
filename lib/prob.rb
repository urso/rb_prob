
# The Probably module provides functions and a discrete Distribution class for
# monadic functional probabilistic programming in ruby.

module Probably

    # simple helper function running a given block with its first argument and
    # returns first argument
    def block1(value)
        yield value
        value
    end

    # given a block return a new Proc defined on range [0..1]
    def mk_shape_fn
        proc { |x|
            if x < 0 || x > 1.0 then 0 else yield x end
        }
    end

    # creates a Proc computing a gaussian distribution
    # in range [0..1] given a mean and deviation
    def normal_dist(mean, dev)
        include Math

        mk_shape_fn { |x|
            u = (x - mean) / dev
            exp (-0.5 * u * u) / sqrt(2 * PI)
        }
    end

    # The Discrete Distribution representation class
    class Distribution
        include Enumerable

        protected
        def init_lsts(data, shape)
            @map = Hash.new(0)
            count = data.length
            data.each_with_index { |value, index| 
                @map[value] += shape.call( Float(index + 1) / count  )
            }
        end

        def init_map(map)
            @map = Hash.new(0)
            map.each { |value, prob| @map[value] = prob }
            self.normalize_probabilities
        end

        def normalize_probabilities
            sum = Float( @map.values.inject(:+) )
            @map.keys.each { |value| @map[value] /= sum } if sum != 1.0
        end

        public

        # Creates a new Discrete Distribution with
        # said constructor type (init_type) and initial data
        # upon construction the data are automatically normalized
        # if init_type is:
        # - :MAP then the given map use used directly and should not
        #        be used anymore by someone else but the current 
        #        distribution class
        # - :MAPCOPY then the given map is copied for further use
        # - :LISTS then the second parameter is the list of keys and the
        #          third parameter the corresponding list of probabilities
        def initialize(init_type, *data)
            case init_type
                when :MAP 
                    @map = data[0]
                when :MAPCOPY
                    init_map(data[0])
                when :LISTS
                    init_lsts(data[0], data[1])
                else
                    raise "unable to create probability distribution"
            end
            self.normalize_probabilities
        end

        # set of keys in distribution
        def keys
            @map.keys
        end

        # returns normalized distribution removing
        # all nil values.
        # In combination with condition, normalize must be used
        # to compute normalization of bayes theorem
        def normalize
            if @map[nil] > 0.0
                filter { |value| value != nil }
            else
                @self
            end
        end

        # returns probability of event val from
        # distribution
        def probability(val)
            @map[val] 
        end

        # use most_probable to retrieve most probable event and
        # its probability from given distribution
        def most_probable
            @map.reduce { |best, value|
                if best[1] < value[1] then value else best end
            }
        end

        # randomly pick a key-value with respect to its probability
        # in given distribution
        def pick
            tst = rand
            sum = 0
            @map.each do |value, prob|
                sum += prob
                return value,prob if tst < sum
            end
            return nil
        end

        def each
            @map.each { |value, prob| yield prob, value }
        end

        def map
            tmp = Hash.new(0)
            @map.each do |value, prob|
                tmp[yield(value)] += prob
            end
            Distribution.new(:MAP, tmp)
        end

        def filter
            Distribution.new :MAP, @map.reject { |value,prob|
                !(yield value)
            }
        end

        def reject
            Distribution.new :MAP, @map.reject { |value, prob|
                yield value
            }
        end

        def query?
            @map.reduce(0) {|probability, (dat,dp)|
                if yield dat then probability + dp
                else probability end
            }
        end

        def join
            tmp = Hash.new(0)

            @map.each do |dist, p1|
                dist.each do |p2, value|
                    tmp[value] += p1 * p2 
                end
            end
            Distribution.new(:MAP, tmp)
        end

        def dep
            Distribution.new :MAP, block1(Hash.new(0)) {|m|
                @map.each do |key, p1|
                    tmp = yield key
                    if tmp != nil
                        tmp.each do |p2, value|
                            m[value] += p1 * p2
                        end
                    else
                        m[nil] += p1
                    end
                end
                }
        end

        def event_dep(pred)
            self.dep {|value|
                if !pred.call value 
                    nil
                else 
                    yield value
                end
            }
        end

        def mult(dist2)
            self.dep do |k|
                if block_given? 
                    dist2.map { |k2| yield(k, k2) }
                else      
                    dist2.map { |k2| [k, k2] }
                end
            end
        end

        def * (other)
            self.mult other
        end

        # computes expectation given that keys in distribution
        # are numeric
        def expectation
            @map.reduce(0) {|sum, (value, p)| sum + value.to_f * p }
        end

        # computes variance given that keys in distribution
        # are numeric
        def variance
            expected = self.expectation
            @map.reduce(0) {|sum, (value,p)| 
                tmp = (value.to_f - expectation)
                sum + tmp * tmp * p 
            }
        end

        # computes standard deviation given that keys in distribution
        # are numeric
        def std_dev
            Math.sqrt( self.variance )
        end

        def to_s
            @map.reduce("") { |str,(value, prob)|
                str + "#{value} : #{prob * 100} %\n"
            }
        end

        def distance(other)
            (self.keys | other.keys).reduce(0) {|sum, value|
                tmp = self.probability(value) - other.probability(value)
                sum + tmp * tmp
            }
        end

        def adjust_min(new_min = 0.01)
            tmp = Hash.new(0)
            self.each do |prob, value|
                tmp[value] = if prob > new_min then prob else new_min end
            end
            Distribution.new :MAP, tmp
        end
    end

    # create uniformly distributed Distribution from array of values
    def uniform(data)
        Distribution.new :LISTS, data, mk_shape_fn {|x| 1}
    end

    # creates linearly distributed Distribution from array of values
    def linear(data)
        Distribution.new :LISTS, data, mk_shape_fn {|x| x }
    end

    # creates exp(-x) distributed Distribution from array of values
    def nexp(data)
        Distribution.new :LISTS, data, mk_shape_fn {|x| Math.exp(-x) }
    end

    # creates Distribution from array of values using a gaussian distribution
    def normal(data, mean = 0.5, dev = 0.5)
        Distribution.new :LISTS, data, normal_dist(mean, dev)
    end

    # creates a distribution from first array holding the distribution
    # values and second one the corresponding probabilities (do be normalized)
    # - data: array of input values
    # - dist: array of probabilities
    def enum_dist(data, dist)
        dist_len = dist.length

        if data.length != dist_len
            raise "data and distribution length must be equal"
        end

        Distribution.new :LISTS, data, mk_shape_fn {|i| 
            dist[i * dist_len - 1]
        }
    end

    # Creates a new probability distribution from given map:
    # m = { key1 => probability1, key2 => probability2, key3 => ... }
    def dist_from_map(m)
        Distribution.new :MAPCOPY, m
    end

    def dist_with(data, &blk)
        Distribution.new :LISTS, data, mk_shape_fn(&blk)
    end

    def choose(prob, value, other)
        Distribution.new :MAP, block1(Hash.new(0)) { |tmp|
            tmp[value] = prob
            tmp[other] = 1 - prob
        }
    end

    def mk_const(value)
        Distribution.new :MAP, block1(Hash.new(0)) { |tmp|
            tmp[value] = 1
        }
    end

    def histogram(iter)
        block1(Hash.new(0)) do |tmp|
            iter.each do |value|
                tmp[value] += 1
            end
        end
    end

    def condition(bool)
        if bool then yield else nil end
    end

    # events
    def mk_event(&fn)
        fn
    end

    def just(default)
        mk_event {|value| default == value}
    end

    def if_just(default)
        if default == nil then proc {|value| true }
        else proc {|value| default == value } end
    end

    def one_of(*elems)
        proc {|value| elems.include? value }
    end
    
end

