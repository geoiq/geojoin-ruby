Author:: Schuyler Erle <schuyler@entropyfree.com>

The Geojoin library provides a mechanism for building an in-memory spatial
index of a set of geographic features, and for efficiently querying that
index.

The use of the Geojoin library is best illustrated with a simple example,
using GeoRuby to read from a pair of Shapefiles.

  index = Geojoin::Index.new()

  GeoRuby::Shp4r::ShpFile.open(file).each do |record|
    wkb = record.geometry.as_wkb
    index << Geojoin::Feature.new(wkb, record.data)
  end

  GeoRuby::Shp4r::ShpFile.open(another_file).each do |record|
    wkb = record.geometry.as_wkb
    query = Geojoin::Feature.new(wkb, record.data)
    index.contained_by(query) {|match|
        # do something with the two feature objects here
    }
  end

Please refer to the rdoc documentation for specific details.
