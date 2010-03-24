
Introduction
============

rb_prob is a simple monadic probabilistic programming library for ruby.
Using monads directly can become quite messy. See package 
[rb_probdsl](http://github.com/urso/rb_probdsl) for implicit probabilistic
programming which uses rb_prob as backend (So one can mix the best of both
worlds...)

Installation
============

## Install Gem

rb_prob is available via rubygems.org and be installed using rubygems:

    $ gem install rb_prob

## Install From Source

1. get the source 
    - from github: 

        $ git clone git://github.com/urso/rb_prob.git

    - or download zip file from http://github.com/urso/rb_prob/zipball/master
    - or download tarball from http://github.com/urso/rb_prob/tarball/master
      
2. install the gem (in source directory):

    $ gem build rb_prob.gemspec
    $ sudo gem install rb_prob

Usage:
======

To use rb_prob you need to use rubygems and require the library:

    require 'rubygems'

    require 'prob'
    include Probably # optional, but will save some typing

TODO: explain how to combine probabilities and different methods of applying
events and doing bayesian inference.

Examples
========

The 'examples' directory contains documented examples describing the problem and
solution with forumlas and code. It is recommended to read them to get a
feeling for how rb_prob and monadic probabilistic programming works.

Recommended reading order:

- examples/diagnosis.rb  # most basic bayesian inference example
- examples/montyhall.rb  # monty hall problem/paradox
- examples/alarm.rb      # example from Artificial Intelligence - A Modern Approach
- example/spamplan.rb    # a spam filter 

