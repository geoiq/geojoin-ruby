# include <vector>
# include <string>
# include <patl/trie_map.hpp>
# include <patl/levenshtein.hpp>

using namespace uxn::patl;
using namespace std;

namespace FuzzyMatch {
    typedef trie_map<string, void *> trie;
    typedef levenshtein_tp_distance<trie, true> edit_distance;
    class Index { 
        trie index;
      public:
        static const size_t not_found = ~0u;
        typedef trie::iterator iterator;
        iterator begin(void) { return index.begin(); };
        iterator end(void) { return index.end(); };
        iterator find (const string &key) { return index.find(key); };
        bool insert(const string &s, void *d);
        size_t match(vector<string> &results,
            const string &target, unsigned int max_dist);
        size_t match(vector<string> &results, const string &target);
    };
};
