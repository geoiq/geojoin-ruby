require 'geos'

# :title:Geojoin
# :include:README.txt
module Geojoin
  # The Feature class encapsulates the relationship between a geometry and
  # a data object. 
  class Feature
    @@wkb_in = nil
    @@wkt_in = nil
    attr_accessor :geometry
    attr_accessor :data

    # The new() method takes two arguments, a geometry, and a data object.
    # 
    # The geometry object can be either a Geos::Geometry or a string. If it is
    # a string, it must be a geometry in either WKT, WKB, or "WKB hex" format,
    # and the new() method will automagically figure out which. The Feature
    # class stores geometries internally as Geos::Geometry objects.
    #
    # The data argument can be any Ruby object.
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
    
    private

    def wkb_in
      @@wkb_in = Geos::WkbReader.new unless @@wkb_in
      @@wkb_in
    end
    def wkt_in
      @@wkt_in = Geos::WktReader.new unless @@wkt_in
      @@wkt_in
    end

    protected

    # Return the (possibly cached) centroid of the feature's geometry.
    def centroid
      contains_centroid? # make sure the centroid is calculated
      @centroid
    end

    # Does the geometry contain its own centroid? This value is cached
    # after the first time it's computed.
    def contains_centroid?
      unless @centroid
        @centroid = @geometry.centroid
        @contains_centroid = @geometry.contains? @centroid
      end
      @contains_centroid
    end
  end

  # The Relation class computes the geometric relationship between
  # two features, and provides the full set of DE-9IM predicates:
  #
  # * equal?
  # * disjoint?
  # * touch?
  # * overlap?
  # * cross?
  # * within?
  # * contain?
  # * intersect?
  class Relation
    attr_accessor :matrix
    # The new() method takes two Feature objects as its arguments.
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
    # DE-9IM defines intersect? as the inverse of disjoint?
    def intersect?
      not disjoint?
    end
    # The predicates() class method returns the list of available predicates.
    def self.predicates
      (@@predicates.keys + ["intersect"]).map {|pred| "#{pred}?".to_sym}
    end
  end

  # The Index class provides an in-memory spatial index of features,
  # and methods for iterating over them efficiently.
  # 
  # The Index class wraps the STR tree class provided by GEOS. The STR tree
  # structure is very fast on queries, but its primary limitation is that the
  # index can be built only once. The first time that a spatial query is
  # performed, the index is constructed and becomes read-only. Therefore, you
  # must add all of the features you wish to query against to the index
  # *first*, before performing any queries against it.
  #
  # All of the query methods in this class take a "query" feature as an
  # argument. The containment-testing query method presume that the query
  # feature is a (multi)polygon.
  class Index
    private

    def type_check (feature)
      raise "only Geojoin::Features can be passed to a Geojoin::Index" \
        unless feature.kind_of? Feature
    end

    def polygon_check (feature)
      # TODO: finish implementing this
      raise "this method may only be called with a Geojoin::Feature " \
        + "containing a (multi)polygon geometry." unless true
    end

    public

    # The new() method takes an optional Array of features.
    def initialize (features=[])
      capacity = features.any? ? features.length : 10
      @tree   = Geos::STRtree.new(capacity)
      features.each {|f| self << f}
    end

    # Add a feature to the index. The << method takes either a
    # Feature object or a two-element Array as its sole argument. If an
    # Array is provided, its contents are used as the arguments to
    # Feature.new(), and then the new feature is inserted into the index.
    def << (feature)
      # TODO: raise an error if the index is already built
      feature = Feature.new(*feature) if feature.kind_of? Array
      type_check feature
      @tree.insert feature.geometry, feature
    end

    # Iterates over the index, passing each feature to the given block.
    # The each() method does *not* trigger the construction of the index.
    def each 
      @tree.each {|feature| yield feature}
    end
  
    # Given a query feature, iterates over all features in the index
    # that are contained by the query feature, and yields each to the given
    # block. Presumes that the query feature is a (multi)polygon.
    #
    # The precise algorithm used for testing for containment is as follows:
    #
    # * Does the indexed feature contain its own centroid, and, if so, then
    #   does the query feature contain the indexed feature's centroid?
    # * Otherwise, does the query feature completely contain the
    #   indexed feature?
    # * Otherwise, does the query feature contain the indexed feature's
    #   centroid, *and* intersect with the indexed feature?
    #
    # Using these criteria, every feature in the index will be
    # mapped one-to-one with a set of non-overlapping query geometries
    # encompassing the geometric plane.
    #
    # Calling this method causes the index to become read-only.
    def contained_by (feature)
      type_check feature
      polygon_check feature
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

    # Given a query feature, iterates over all features in the index
    # that intersect with the query feature, and yields each to the given
    # block.
    #
    # Calling this method causes the index to become read only.
    def intersects_with (feature)
      type_check feature
      prepared = Geos::Prepared.new(feature.geometry)
      @tree.query(feature.geometry) {|match|
        yield match if prepared.intersects? match.geometry
      }
    end

    # Given a query feature, iterates over all features in the index whose
    # bounding boxes intersect with that of the query feature, and yields
    # to the given block an array consisting of the indexed feature and
    # the corresponding Relation object.
    #
    # Calling this method causes the index to become read only.
    def relates_to (feature)
      type_check feature
      @tree.query(feature.geometry) {|match|
        yield [match, Relation.new(feature, match)]
      }
    end

    # Returns a count of all features in the index contained by the
    # given query feature.
    #
    # Calling this method causes the index to become read only.
    def count (feature)
      total = 0
      contained_by(feature) {total += 1}
      total
    end

    # Returns the sum of a value across all features in the index contained by
    # the given query feature. The value of each feature is obtained by
    # looking up the provided key in the indexed feature's data object.
    #
    # Calling this method causes the index to become read only.
    def sum (feature, key)
      total = 0
      contained_by(feature) {|other| total += other[key]}
      total
    end

    # Returns the mean value across all features in the index contained by
    # the given query feature. The value of each feature is obtained by
    # looking up the provided key in the indexed feature's data object.
    #
    # Calling this method causes the index to become read only.
    def mean (feature, key)
      items = total = 0
      contained_by(feature) {|other| items += 1; total += other[key]}
      items / total.to_f
    end

    # Returns the population standard deviation across all features in the
    # index contained by the given query feature. The value of each feature is
    # obtained by looking up the provided key in the indexed feature's data
    # object.
    #
    # Calling this method causes the index to become read only.
    def stddev (feature, key)
      items = mean = m2 = 0
      contained_by(feature) {|other| 
        n = n + 1
        delta = other[key] - mean
        mean = mean + delta/n.to_f
        m2 = m2 + delta*(other[key] - mean)
      }
      Math.sqrt(m2/n.to_f)
    end

    # Returns the minimum value across all features in the index contained by
    # the given query feature. The value of each feature is obtained by
    # looking up the provided key in the indexed feature's data object.
    #
    # Calling this method causes the index to become read only.
    def min (feature, key)
      value = nil
      contained_by(feature) {|other|
        value = other[key] if value.nil? or value > other[key]
      }
      value
    end

    # Returns the maximum value across all features in the index contained by
    # the given query feature. The value of each feature is obtained by
    # looking up the provided key in the indexed feature's data object.
    #
    # Calling this method causes the index to become read only.
    def max (feature, key)
      value = nil
      contained_by(feature) {|other|
        value = other[key] if value.nil? or value < other[key]
      }
      value
    end
  end
end
