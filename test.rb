#!/usr/bin/ruby

require 'rubygems'
require 'geo_ruby'
require 'lib/geojoin'
require 'test/unit'

class TestGeojoinIndex < Test::Unit::TestCase
  def find_file (file)
    File.join(File.dirname(__FILE__), "sample", file)
  end
  def load_shapefile (file, field, target)
    file = find_file file
    GeoRuby::Shp4r::ShpFile.open(file).each do |record|
      wkb = record.geometry.as_wkb
      id = record.data[field]
      target << Geojoin::Feature.new(wkb, id)
    end
  end
  def load_fixture (file)
    fixture = nil
    File.open(find_file(file)) {|f|
      fixture = f.readlines.map {|line| line.chomp}
    }
    fixture
  end
  def setup
    @features = []
    load_shapefile "de_county.shp", "NAME", @features
    @index = Geojoin::Index.new
    load_shapefile "de_place.shp", "NAME", @index
  end
  def test_feature
    point = Geojoin::Feature.new("POINT(123 456)", "test")
    assert_equal point.geometry.coord_seq.get_x(0), 123.0
    assert_equal point.geometry.coord_seq.get_y(0), 456.0
    assert_equal point.data, "test"
  end
  def test_geos
    point = Geojoin::Feature.new("POINT(0 0)", "point")
    poly  = Geojoin::Feature.new("POLYGON((-1 -1, -1 1, 1 1, 1 -1, -1 -1))", "poly")
    assert poly.geometry.contains? point.geometry
    prepared = Geos::Prepared.new(poly.geometry)
    assert prepared.contains_properly? point.geometry
    assert prepared.contains? point.geometry
  end
  def test_point_in_poly
    point = Geojoin::Feature.new("POINT(0 0)", "point")
    poly  = Geojoin::Feature.new("POLYGON((-1 -1, -1 1, 1 1, 1 -1, -1 -1))", "poly")
    index = Geojoin::Index.new
    index << point
    found = false
    index.contained_by(poly) {|f| found = f.data}
    assert_equal found, "point"
  end
  def test_point_in_multipoly
    point = Geojoin::Feature.new("POINT(0 0)", "point")
    poly  = Geojoin::Feature.new("MULTIPOLYGON(((-5 -4, -4 -4, -4 -5, -5 -5, -5 -4))," + 
                                 "((-1 -1, -1 1, 1 1, 1 -1, -1 -1)))", "poly")
    #writer = Geos::WktWriter.new
    #p writer.write(poly.geometry.envelope)
    index = Geojoin::Index.new
    index << point
    found = false
    index.contained_by(poly) {|f| found = f.data}
    assert_equal found, "point"
  end
  def test_type_check
    begin
      @index << 5
      assert false
    rescue RuntimeError
      assert true
    end
  end
  def test_each
    count = 0
    @index.each {|f| count += 1}
    assert_equal count, 75 # places in Delaware
    assert_equal @index.built, false
  end
  def test_built
    assert_equal @index.built, false
    @index.contained_by(@features[0]) {}
    assert_equal @index.built, true
    begin
      @index << @features[0]
      assert false
    rescue RuntimeError
      # assert_raise RuntimeError here gives me NoMethodError
      assert true
    end
  end
  def test_polygon_check
    point = Geojoin::Feature.new("POINT(0 0)", "I'm a point")
    begin
      @index.contained_by(point) {}
      assert false
    rescue RuntimeError
      # assert_raise RuntimeError here gives me NoMethodError
      assert true
    end
  end
  def test_contained_by
    fixture = load_fixture "contain.txt"
    count = 0
    @features.each {|feat1|
      @index.contained_by(feat1) {|feat2|
        item = [feat1.data,feat2.data].join ","
        assert fixture.member?(item), "contain:"+item
        count += 1
      }
    }
    assert_equal count, fixture.length
  end
  def test_intersects_with
    fixture = load_fixture "intersect.txt"
    count = 0
    @features.each {|feat1|
      @index.intersects_with(feat1) {|feat2|
        item = [feat1.data, feat2.data].join ","
        assert fixture.member?(item), "intersect:"+item
        count += 1
      }
    }
    assert_equal count, fixture.length
  end
  def test_relates_to
    fixture = load_fixture "relate.txt"
    count = 0
    @features.each {|feat1|
      @index.relates_to(feat1) {|feat2, relation|
        item = [feat1.data, feat2.data, relation.matrix].join ","
        assert fixture.member?(item), "relate:"+item
        count += 1
      }
    }
    assert_equal count, fixture.length
  end
  def test_count
    fixture = load_fixture "count.txt"
    count = 0
    @features.each {|feat1|
      item = [feat1.data, @index.count(feat1)].join ","
      assert fixture.member?(item), "count:"+item
      count += 1
    }
    assert_equal count, fixture.length
  end
  def test_wkb
    Geojoin::Feature.new("01010000008EBCA5D242855EC038FA71980DB64240", "point")
  end
end
