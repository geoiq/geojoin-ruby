require 'rubygems'
require 'geo_ruby'
require 'geojoin'

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

def test_contain (out, index, features, quiet=false)
  features.each {|feat1|
    index.contained_by(feat1) {|feat2|
      out.print "#{feat1.data},#{feat2.data}\n"
    }
  }
end

def test_relate (out, index, features, quiet=false)
  features.each {|feat1|
    index.relates_to(feat1) {|feat2, relation|
      out.print "#{feat1.data},#{feat2.data},#{relation.matrix}\n"
    } 
  }
end

def test_count (out, index, features)
  features.each {|feat| out.print feat.data, ",", index.count(feat), "\n"}
end

def do_test
  features = load_features(ARGV[0], ARGV[1])
  index = load_index(ARGV[2], ARGV[3])
  test_contain(File.new("contain.txt","w"),index, features)
  test_relate(File.new("relate.txt","w"),index, features)
  test_count(File.new("count.txt","w"),index, features)
end

do_test
