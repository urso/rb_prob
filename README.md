
Introduction
------------

rb_prob is a simple monadic probabilistic programming library for ruby.

Installation
------------

rb_prob comes with a gem specification, but is not available from rubygem.com
yet. So to install type:

    $ gem build rb_prob.gemspec
    $ sudo gem install rb_prob

Usage:
------

To use rb_prob you need to use rubygems and require the library:

    require 'rubygems'

    gem 'rb_prob'; require 'prob'
    include Probably # optional, but will save some typing

TODO: explain how to combine probabilities and different methods of applying
events and doing bayesian inference.

Examples
--------

The examples directory contains documented examples describing the problem and
solution with forumlas and code. It is recommended to read them to get a
feeling for how rb_prob and monadic probabilistic programming works.

Recommended reading order:

- examples/diagnosis.rb  # most basic bayesian inference example
- examples/montyhall.rb  # monty hall problem/paradox
- examples/alarm.rb      # example from Artificial Intelligence - A Modern Approach
- example/spamplan.rb    # a spam filter 

