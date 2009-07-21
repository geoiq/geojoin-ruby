#!/usr/bin/ruby
#
# a variant of spell.rb that normalizes Unicode characters
# to match café to cafe. requires unicode gem.

$LOAD_PATH << '..'

require 'fuzzymatch'
require 'rubygems'
require 'unicode'
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
  def to_ascii
    if self =~ /[\x7f-\xff]/o
      Unicode.normalize_KD(self).unpack('U*').select{ |cp| cp < 127 }.pack('U*')
    else
      self
    end
  end
end

def cleanup (word)
  #word.to_ascii.gsub(/\W/o, '')
  word
end

if ARGV.empty?
  puts "Usage: spell.rb [<dictionary>] <word>"
  exit
elif ARGV.length == 1
  dictionary = '/usr/share/dict/words'
  lookup = ARGV[0]
else
  dictionary, lookup = ARGV[0..1]
end

idx = Fuzzymatch::Index.new()

puts "Loading and normalizing the dictionary. (may take a while)"
File.new(dictionary).each_line {|word|
  word = word.chomp.to_u('LATIN1')
  key  = cleanup word
  idx.insert(key, word)
}
puts "Looking up possible spellings for \"#{lookup}\"..."
dist, matches = idx.match(cleanup(lookup))
if matches.any?
  puts "#{matches.size} word(s) found at distance #{dist}."
  matches.each {|word|
    puts idx.find(word)
  }
else
  puts "0 matches found."
end
