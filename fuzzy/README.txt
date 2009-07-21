= Summary

Fuzzymatch is a C++ library, with Ruby bindings, providing fast in-memory fuzzy
string matching using suffix trees and the Levenshtein-Damerau edit distance
measure. Fuzzymatch is built on PATL, a BSD licensed library, from Google Code:

    http://code.google.com/p/patl/

= Prerequisites

You will need Ruby, g++, and SWIG (>= 1.3) to build the fuzzymatch library.

= Building fuzzymatch

You can simply build and install the gem:

  gem build fuzzymatch.gemspec

If you don't want to install the gem, you can build fuzzymatch manually:

  ruby extconf.rb
  make

= Synopsis

    require 'fuzzymatch'

    idx = Fuzzymatch::Index.new()

    File.new(ARGV[0]).each_line {|x|
      idx.insert(x.chomp)
    }
    dist, matches = idx.match(ARGV[1])
    p dist, matches

Also, try the examples in examples/.
