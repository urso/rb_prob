#!/usr/bin/env ruby

require '../src/prob'
include Probably

S = [:Spam, :Ham]

module SpamDatabaseProbabilities
    # probabilities
    #
    # S = {:Spam, :Ham} ; Set of possible message type
    # P(S) <- prior probability
    #
    # W = {set of known words}
    # P(W|S) <- likelyhood
    
    def pMsgType # P(S)
        enumDist types, @msgCounts
    end

    def pWord(word, type) # P(W == word | S == type)
        n = countWord(word, type).to_f
        total = countType(type).to_f
        choose n / total, true, false
    end

    # P(S | W == word) = < P(W == word | S) * prior >
    def pHasWord(word, prior = pMsgType)    
        prior.dep {|t|
            pWord(word, t).event_dep(just true) {
                mkState(t)
            }
        }.normalize
    end

    #P(S | W1 == word1, W2 == word2, ...) = < P(S|W1) * P(S|W2) * ...>
    def pHasWords(words, prior = pMsgType)  
        words.reduce(prior) {|p,w| pHasWord(w, p) }
    end
end

class SpamBaseKnowledge
    include SpamDatabaseProbabilities

    def initialize
        @msgCounts = [102, 57]
        @wordCountTable = block1({
            "the" => [1, 2],
            "quick" => [1, 1],
            "brown" => [0, 1],
            "fox" => [0, 1],
            "jumps" => [0, 1],
            "over" => [0, 1],
            "lazy" => [0, 1],
            "dog" => [0, 1],
            "make" => [1, 0],
            "money" => [1, 0],
            "in" => [1,0],
            "online" => [1,0],
            "casino" => [1, 0],
            "free" =>  [57, 6],
            "bayes" => [1, 10],
            "monad" => [0, 22],
            "hello" => [30, 32],
            "asdf"  => [40, 2]
        }) { |h| h.default = [0,0] }
    end

    def types
        S
    end

    def knownWords
        @wordCountTable.keys
    end

    def countType(type)
        if type != :Spam && type != :Ham
            return 0
        else
            @msgCounts[ type2Index type ]
        end
    end

    def countWord(word, type)
        @wordCountTable[word][ type2Index type ]
    end

    private
    def type2Index(type)
        if type == :Spam then 0 else 1 end
    end
end

NaiveBayesianStrategie = proc {|classifiers, prior, _, _|
    # use naive bayesian to find probability of spam using classifiers
    classifiers.reduce(prior) {|prior, prob| 
        prior.dep {|type|
            choose(prob.probability(type),true,false).event_dep(just true) {
                mkState type
            }
        }
    }.normalize
}

FisherStrategie = proc {|classifiers, prior, n, words|
    hypothesis = NaiveBayesianStrategie.call(classifiers, prior, n, words)
    map = Hash.new(0)

    dof = classifiers.length # dof / 2

    hypothesis.each do |k,p|
        chi = -2.0 * Math.log(p)
        m = 0.5 * chi;
        t = Math.exp(-m)

        # compute inverse chi square
        tmp = 1.upto(dof-1).reduce(t) {|sum,i|
            t *= m / i.to_f
            sum + t
        }

        map[k] = if tmp < 1.0 then tmp else 1.0 end
    end

    map2 = Hash.new(0)
    for k in map.keys
        for other in map.keys
            if k != other
                map2[k] += 1 - map[other]
            end
        end
    end
    p map2

    Distribution.new :MAP, map2
}

class SpamClassifier

    def initialize(knowledge, strategie)
        @knowledge = knowledge
        @classifiers = {}
        @strategie = strategie

        buildClassifiers {|w,s,probs|
            @classifiers[w] = [s,probs]
        }
    end

    def pMsgTypeByWords(words, n = 15, prior = @knowledge.pMsgType)
        @strategie.call(findClassifiers(words, n), prior, n, words)
    end

    def classify(words, n = 15)
        pMsgTypeByWords(words, n).most_probable
    end

    private
    def characteristic(f)
        f.call uniform(@knowledge.types)
    end

    def score(f = nil, &blk)
        pDistance( characteristic(f || blk), uniform(@knowledge.types))
    end

    def buildClassifiers
        @knowledge.knownWords.each {|w,types|
            s = score {|prior| @knowledge.pHasWord(w,prior)}
            probs = adjustMinimums(@knowledge.pHasWord(w, uniform(S)))
            yield w, s, probs
        }
    end

    def findClassifiers(words, n)
        classifiers = words.map {|w| [w, @classifiers[w]] }.delete_if {|w,c| c == nil}
        classifiers.sort! {|x,y| x[1][0] <=> y[1][0]}
        classifiers[0,n].map {|w,(s,prob)| 
            prob 
        }
    end
end

# learned database

classifiers = [ SpamClassifier.new(SpamBaseKnowledge.new, NaiveBayesianStrategie), 
                SpamClassifier.new(SpamBaseKnowledge.new, FisherStrategie) ]

testCorpus = [["free"],
              ["monad"],
              ["free", "asdf", "bayes", "quick", "jump", "test"],
              ["free", "monad", "asdf", "bayes", "quick", "jump", "test"]
             ]

puts "\ntest classifier"
testCorpus.each do |data|
    printf "use corpus: #{data}\n"
    classifiers.each do |c|
        puts c.pMsgTypeByWords(data)
        puts ""
    end
end

