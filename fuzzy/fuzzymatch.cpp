# include "fuzzymatch.h"
# include <queue>

using namespace uxn::patl;
using namespace std;

namespace FuzzyMatch {
    bool Index::insert(const string &s, void *d) {
        pair<Index::iterator, bool> result;
        result = index.insert(make_pair(s, d));
        return result.second;
    }

    typedef trie::const_partimator<edit_distance> Search;
    size_t Index::match(vector<string> &results,
            const string &target, unsigned int max_dist) {
        edit_distance partial_match(index, max_dist, target);
        vector<Search> iters;
        Search it = index.begin(partial_match),
              end = index.end(partial_match);
        size_t closest = not_found;
        for (; it != end; ++it) {
            unsigned int distance = it.decis().distance();
            if (distance > closest) continue;
            if (distance < closest) {
                iters.clear();
                closest = distance;
            }
            iters.push_back(it);
        }
        vector<Search>::iterator result = iters.begin(),
                             result_end = iters.end();
        for (;result != result_end; result++) {
            results.push_back((*result)->first);
        }
        return closest;
    }

    size_t Index::match(vector<string> &results, const string &target) {
        size_t closest;
        for (size_t max_dist = 0; max_dist < target.length()-1; max_dist++) {
            closest = match(results, target, max_dist);
            if (closest != not_found) return closest;
        }
        return not_found;
    }
};
