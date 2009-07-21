Gem::Specification.new do |s|
    s.name          = 'Fuzzymatch'
    s.version       = "1.0.0"
    s.author        = "Schuyler Erle"
    s.email         = 'schuyler@entropyfree.com'
    s.description   = "Fast in-memory fuzzy string matching."
    s.summary       = "Based on PATL from Google Code."
    s.homepage      = "http://entropyfree.com/"
    s.requirements  = ["SWIG (> 1.3), and a C++ compiler"]
    s.platform      = Gem::Platform::CURRENT
    s.extensions    = "extconf.rb"
    s.files         = Dir["fuzzymatch.*"] + Dir["patl/*"] + Dir["patl/*/*"]
    s.test_files    = "test.rb"
    s.has_rdoc      = true
    s.extra_rdoc_files = ["README.txt"]
end
