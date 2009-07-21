#!/usr/bin/ruby

$LOAD_PATH.push '..'

require 'fuzzymatch'

if ARGV.empty?
  puts "Usage: spell.rb [<dictionary>] <word>"
  exit
elsif ARGV.length == 1
  dictionary = "/usr/share/dict/words"
  lookup = ARGV[0]
  lookup = 'café'
else
  dictionary, lookup = ARGV[0..1]
end

idx = Fuzzymatch::Index.new()

line = 0
File.new(dictionary).each_line {|word|
  line += 1
  idx.insert(word.chomp, line)
}
puts "Looking up possible spellings for \"#{lookup}\"..."
dist, matches = idx.match(lookup)
if matches.any?
  puts "#{matches.size} word(s) found at distance #{dist}."
  matches.each {|word|
    puts "#{word} (line #{idx.find(word)})"
  }
else
  puts "0 matches found."
end
