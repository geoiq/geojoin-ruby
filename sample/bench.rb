require 'rubygems'
require 'benchmark'
require 'geo_ruby'
require 'geojoin'

#GC.disable

def load_features (file, idfield)
  geoms = []
  GeoRuby::Shp4r::ShpFile.open(file).each do |record|
    wkb = record.geometry.as_wkb
    id = record.data[idfield]
    geoms << Geojoin::Feature.new(wkb, id)
  end
  geoms
end


def load_index (file, idfield)
  index = Geojoin::Index.new()
  GeoRuby::Shp4r::ShpFile.open(file).each do |record|
    wkb = record.geometry.as_wkb
    id = record.data[idfield]
    index << Geojoin::Feature.new(wkb, id)
  end
  index
end

def test_contain (index, features, quiet=false)
  count = 0
  features.each {|feat1|
    index.contained_by(feat1) {|feat2|
      print "#{feat1.data} <- #{feat2.data}\n" unless quiet
      count += 1
    }
  }
  p count unless quiet
end

def test_relate (index, features, quiet=false)
  features.each {|feat1|
    index.relates_to(feat1) {|feat2, relation|
      print "#{feat1.data} #{feat2.data} " unless quiet
      Geojoin::Relation.predicates.each {|pred|
        print "#{pred} " if relation.send pred and not quiet
      }
      print "\n" unless quiet
    } 
  }
end

def test_count (index, features)
  p features.map {|feat| [feat.data, index.count(feat)]}
end

def do_test
  features = load_features(ARGV[0], ARGV[1])
  index = load_index(ARGV[2], ARGV[3])
  test_contain(index, features)
  test_relate(index, features)
  test_count(index, features)
end

def do_benchmark
  GC.disable
  features = index = nil
  Benchmark.bm do |x|
      x.report("load_features a  ") { features = load_features(ARGV[0],ARGV[1]) }
      x.report("load_features b  ") { load_features(ARGV[2],ARGV[3]) }
      x.report("load_index       ") { index = load_index(ARGV[2],ARGV[3]) }
      x.report("test_contain     ") { test_contain(index,features,true) }
      x.report("test_100_contain ") { 100.times {test_contain(index,features,true)} }
      x.report("test_relate      ") { test_relate(index,features,true) }
  end
  GC.enable
end

ARGV = ["de_county.shp","NAME","de_place.shp","NAME"] unless ARGV.any?
raise "bench.rb <shape1> <field1> <shape2> <field2>" unless ARGV.length == 4
do_test
do_benchmark
