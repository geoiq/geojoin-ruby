require 'geos'

module Geojoin
  class Feature
    @@wkb_in = nil
    @@wkt_in = nil
    attr_accessor :geometry
    attr_accessor :data
    def initialize (geometry, data)
      if geometry.kind_of? Geos::Geometry
        @geometry = geometry.clone
      elsif geometry.match /^[0-9a-f]$/io
        # WKB in hex format
        @geometry = wkb_in.readHEX geometry
      elsif ('A'..'Z').member? geometry[0]
        # WKT
        @geometry = wkt_in.read geometry
      else
        # WKB
        @geometry = wkb_in.read geometry
      end
      raise "couldn't parse geometry" unless @geometry
      @data = data
    end
    def wkb_in
      @@wkb_in = Geos::WkbReader.new unless @@wkb_in
      @@wkb_in
    end
    def wkt_in
      @@wkt_in = Geos::WktReader.new unless @@wkt_in
      @@wkt_in
    end
    def centroid
      contains_centroid? # make sure the centroid is calculated
      @centroid
    end
    def contains_centroid?
      unless @centroid
        @centroid = @geometry.centroid
        @contains_centroid = @geometry.contains? @centroid
      end
      @contains_centroid
    end
  end
  class Relation
    attr_accessor :matrix
    def initialize (feat1, feat2)
      @matrix = feat1.geometry.relate(feat2.geometry)
    end
    # implements DE-9IM
    @@predicates = {
      "equal"     => "T*F**FFF*",
      "disjoint"  => "FF*FF****",
      "touch"     => "FT*******|F**T*****|F***T****",
      "overlap"   => "T*T***T**",
      "cross"     => "T*T******|0********",
      "within"    => "T*F**F***",
      "contain"   => "T*****FF*",
    }
    @@predicates.each do |key, match|
      match = match.gsub("T", "\\d").gsub("*", ".")
      match = Regexp.compile("^(?:#{match})$")
      define_method "#{key}?".to_sym do
        (@matrix =~ match) ? true : false
      end
    end
    def intersect?
      not disjoint?
    end
    def self.predicates
      (@@predicates.keys + ["intersect"]).map {|pred| "#{pred}?".to_sym}
    end
  end
  class Index
    private

    def type_check (feature)
      raise "only Geojoin::Features can be passed to a Geojoin::Index" \
        unless feature.kind_of? Feature
    end

    public

    def initialize (features=[])
      capacity = features.any? ? features.length : 10
      @tree   = Geos::STRtree.new(capacity)
      features.each {|f| self << f}
    end
    def << (feature)
      type_check feature
      @tree.insert feature.geometry, feature
    end
    def each 
      @tree.each {|feature| yield feature}
    end
    def contained_by (feature)
      type_check feature
      prepared = Geos::Prepared.new(feature.geometry)
      @tree.query(feature.geometry) {|match|
        if match.contains_centroid?
          contained = prepared.contains_properly? match.centroid
        else
          contained = prepared.contains_properly? match.geometry
          unless contained
            contained = prepared.contains_properly?(match.centroid) \
                    and prepared.intersects?(match.geometry)
          end
        end
        yield match if contained
      }
    end
    def intersects_with (feature)
      type_check feature
      prepared = Geos::Prepared.new(feature.geometry)
      @tree.query(feature.geometry) {|match|
        yield match if prepared.intersects? match.geometry
      }
    end
    def relates_to (feature)
      type_check feature
      @tree.query(feature.geometry) {|match|
        yield [match, Relation.new(feature, match)]
      }
    end
    def count (feature)
      type_check feature
      total = 0
      contained_by(feature) {total += 1}
      total
    end
    def sum (feature, key)
      type_check feature
      total = 0
      contained_by(feature) {|other| total += other[key]}
      total
    end
    def mean (feature, key)
      type_check feature
      items = total = 0
      contained_by(feature) {|other| items += 1; total += other[key]}
      items / total.to_f
    end
    def stddev (feature, key)
      type_check feature
      items = mean = m2 = 0
      contained_by(feature) {|other| 
        n = n + 1
        delta = other[key] - mean
        mean = mean + delta/n.to_f
        m2 = m2 + delta*(other[key] - mean)
      }
      Math.sqrt(m2/n.to_f)
    end
    def min (feature, key)
      type_check feature
      value = nil
      contained_by(feature) {|other|
        value = other[key] if value.nil? or value > other[key]
      }
      value
    end
    def max (feature, key)
      type_check feature
      value = nil
      contained_by(feature) {|other|
        value = other[key] if value.nil? or value < other[key]
      }
      value
    end
  end
end
