Author:: Schuyler Erle <schuyler@entropyfree.com>, for FortiusOne

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

However, the current version of GeoRuby (1.3.4) does not appear to handle
multipolygons correctly, which can result in erroneous results from the Geojoin
index. The following script accomplishes the same purpose as the previous
script, using the Ruby OGR bindings from GDAL:

    require 'geojoin'
    require 'gdal/ogr'

    def load_features(file, idfield)
      geoms = []
      dataset = Gdal::Ogr.open(file)
      layer = dataset.get_layer(0)
      defn = layer.get_layer_defn
      field = defn.get_field_index idfield
      layer.reset_reading
      layer.get_feature_count.times do |i|
        feature = layer.get_feature(i)
        geom = feature.get_geometry_ref
        id = feature.get_field_as_string(field);
        yield Geojoin::Feature.new(geom.export_to_wkb, id)
      end
    end

    index = Geojoin::Index.new

    load_features(point_file, 'POINT_NAME') do |feat|
      index << feat
    end

    load_features(polygon_file, 'POLY_NAME') do |feature|
       index.contained_by(feature){|match|
         puts "#{feature.data} contains #{match.data}"
       }
    end

Please refer to the rdoc documentation for specific details.
