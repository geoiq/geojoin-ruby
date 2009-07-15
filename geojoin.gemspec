Gem::Specification.new do |s|
    s.name          = 'Geojoin'
    s.version       = "1.0.0"
    s.author        = "Schuyler Erle"
    s.email         = 'schuyler@entropyfree.com'
    s.description   = "Fast in-memory spatial indexing and lookup."
    s.summary       = s.description + " Depends on GEOS Ruby bindings."
    s.files         = ["geojoin.rb"]
    s.test_files    = ["test.rb"] + Dir["sample/*"]
    s.has_rdoc      = true
    s.extra_rdoc_files  =   ["README.txt", "INSTALL.txt"]
end
