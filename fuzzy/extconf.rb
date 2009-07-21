require 'mkmf'
$LIBS << " -lstdc++"
message("creating SWIG bindings\n")
system('swig -c++ -ruby fuzzymatch.i')
create_makefile('fuzzymatch')
