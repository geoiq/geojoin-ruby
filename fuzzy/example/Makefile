all: spell

spell: spell.cpp ../fuzzymatch.cpp ../fuzzymatch.h
	g++ -O3 -o spell -I.. spell.cpp ../fuzzymatch.cpp

clean:
	rm -f spell 
