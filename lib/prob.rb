
# The Probably module provides functions and a discrete Distribution class for
# monadic functional probabilistic programming in ruby.

puts 'loading rb_prob'

module Probably

    # simple helper function running a given block with its first argument and
    # returns first argument
    def block1(x, &blk)
        blk.call(x)
        x
    end

    # given a block return a new Proc defined on range [0..1]
    def mkShapeFunction
        proc { |x|
            if x < 0 || x > 1.0 then 0 else yield x end
        }
    end

    # creates a Proc computing a gaussian distribution
    # in range [0..1] given a mean and deviation
    def normalDistShape(mean, dev)
        include Math

        mkShapeFunction { |x|
            u = (x - mean) / dev
            exp (-0.5 * u * u) / sqrt(2 * PI)
        }
    end

    # The Discrete Distribution representation class
    class Distribution
        include Enumerable

        protected
        def initializeLists(data, shape)
            @map = Hash.new(0)
            count = data.length
            data.each_with_index { |val, i| 
                @map[val] += shape.call( Float(i + 1) / count  )
            }
        end

        def initializeMap(m)
            @map = Hash.new(0)
            m.each { |k,v| @map[k] = v }
            self.normalizeProbabilities
        end

        def normalizeProbabilities
            sum = Float( @map.values.inject(:+) )
            @map.keys.each { |k| @map[k] /= sum } if sum != 1.0
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
                    initializeMap(data[0])
                when :LISTS
                    initializeLists(data[0], data[1])
                else
                    raise "unable to create probability distribution"
            end
            self.normalizeProbabilities
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
                filter { |v| v != nil }
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
            r = rand
            sum = 0
            for k,p in @map
                sum += p
                return k,p if r < sum
            end
            return nil
        end

        def each
            @map.each { |k, p| yield p, k }
        end

        def map
            tmp = Hash.new(0)
            for k,p in @map
                tmp[yield(k)] += p
            end
            Distribution.new(:MAP, tmp)
        end

        def filter
            Distribution.new :MAP, @map.reject { |k,v|
                !(yield k)
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

            for dist,p1 in @map
                for p2, k in dist
                    tmp[k] += p1 * p2 
                end
            end
            Distribution.new(:MAP, tmp)
        end

        def dep
            m = Hash.new(0)
            for k1,p1 in @map
                tmp = yield k1
                if tmp != nil
                    for p2, k in tmp
                        m[k] += p1 * p2
                    end
                end
            end
            Distribution.new(:MAP, m)
        end

        def event_dep(pred)
            self.dep {|x|
                if !pred.call x 
                    mkState nil
                else 
                    yield x 
                end
            }
        end

        def mult(dist2)
            self.dep do |k|
                if block_given? then dist2.map { |k2| yield(k, k2) }
                else      dist2.map { |k2| [k, k2] }
                end
            end
        end

        def * (dist2)
            self.mult dist2
        end

        # computes expectation given that keys in distribution
        # are numeric
        def expectation
            @map.reduce(0) {|sum, (k,p)| sum + k.to_f * p }
        end

        # computes variance given that keys in distribution
        # are numeric
        def variance
            expected = self.expectation
            @map.reduce(0) {|sum, (k,p)| 
                tmp = (k.to_f - expectation)
                sum + tmp * tmp * p 
            }
        end

        # computes standard deviation given that keys in distribution
        # are numeric
        def std_dev
            Math.sqrt( self.variance )
        end

        def to_s
            @map.reduce("") { |str,(k,p)|
                str + "#{k} : #{p * 100} %\n"
            }
        end
    end

    # create uniformly distributed Distribution from array of values
    def uniform(data)
        Distribution.new :LISTS, data, mkShapeFunction {|x| 1}
    end

    # creates linearly distributed Distribution from array of values
    def linear(data)
        Distribution.new :LISTS, data, mkShapeFunction {|x| x }
    end

    # creates exp(-x) distributed Distribution from array of values
    def negExp(data)
        Distribution.new :LISTS, data, mkShapeFunction {|x| Math.exp(-x) }
    end

    # creates Distribution from array of values using a gaussian distribution
    def normal(data, mean = 0.5, dev = 0.5)
        Distribution.new :LISTS, data, normalDistShape(mean, dev)
    end

    # creates a distribution from first array holding the distribution
    # values and second one the corresponding probabilities (do be normalized)
    # - data: array of input values
    # - dist: array of probabilities
    def enumDist(data, dist)
        if data.length != dist.length
            raise "data and distribution length must be equal"
        end

        Distribution.new :LISTS, data, mkShapeFunction {|i| dist[i * dist.length - 1]}
    end

    # Creates a new probability distribution from given map:
    # m = { key1 => probability1, key2 => probability2, key3 => ... }
    def mapDist(m)
        Distribution.new :MAPCOPY, m
    end

    def distWithShape(data, &blk)
        Distribution.new :LISTS, data, mkShapeFunction(&blk)
    end

    def choose(p, elem1, elem2)
        tmp = Hash.new(0)
        tmp[elem1] = p
        tmp[elem2] = 1 - p
        Distribution.new :MAP, tmp
    end

    def mkState(a)
        tmp = Hash.new(0)
        tmp[a] = 1
        Distribution.new :MAP, tmp
    end

    def histogram(a)
        block1(Hash.new(0)) do |r|
            for x in a
                r[x] += 1
            end
        end
    end

    def condition(b)
        if b then yield else mkState nil end
    end

    # events
    def mkEvent(&f)
        f
    end

    def just(x)
        mkEvent {|y| x == y}
    end

    def ifJust(x)
        if x == nil then proc {|y| true }
        else proc {|y| x == y } end
    end

    def oneOf(*elems)
        proc {|y| elems.include? y }
    end

    def pDistance(dist1, dist2)
        (dist1.keys | dist2.keys).reduce(0) {|sum,k|
            tmp = dist1.probability(k) - dist2.probability(k)
            sum + tmp * tmp
        }
    end

    def adjustMinimums(dist, newMin = 0.01)
        tmp = Hash.new(0)
        dist.each do |p,k|
            tmp[k] = if p > newMin then p else newMin end
        end
        Distribution.new :MAP, tmp
    end
    
end

