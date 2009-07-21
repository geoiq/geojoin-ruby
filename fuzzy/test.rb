#!/usr/bin/ruby

require 'test/unit'
require 'fuzzymatch'
require 'iconv'

class String
  # borrowed from http://www.jroller.com/obie/entry/fix_that_tranny_add_to
  def to_u (encoding)
    if self =~ /[\x7f-\xff]/o
      Iconv::iconv('UTF-8', encoding, self)[0]
    else
      self
    end
  end
end

class TestFuzzymatch < Test::Unit::TestCase
  DICT_FILE = '/usr/share/dict/words'
  def setup
    @index = Fuzzymatch::Index.new()
    File.new(DICT_FILE).each_line {|word|
      word = word.chomp.to_u('LATIN1')
      @index.insert(word, word)
    }
  end
  def test_match
    [
      ["fuzzy", 0, ["fuzzy"]],
      ["café", 0, ["café"]], # unicode test
      ["fuzzle", 1, %w(fizzle guzzle muzzle nuzzle puzzle)],
      ["grunk", 1, %w(drunk grunt gunk trunk)],
      ["quux", 2, %w(Crux crux flux quad quay queue quid quip quit quiz tux)]
    ].each {|word, ex_dist, ex_matches|
      dist, matches = @index.match(word)
      assert_equal dist, ex_dist
      assert_equal matches, ex_matches
      assert_equal matches[0], @index.find(matches[0])
      if dist == 0
        assert_equal word, @index.find(word)
      else
        assert_nil @index.find(word)
      end
    }
  end
  def test_missing_diacritics
    # FIXME: this is actually a failure, but fixing it entails *either* doing
    # KD-normalization on both sides, and then throwing away the diacritics,
    # *or* supporting wchar_t in the C++.
    dist, matches = @index.match('cafe')
    assert_equal dist, 1
    assert ! matches.member?( "café" )
  end
end
