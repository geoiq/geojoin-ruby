# include <iostream>
# include <iomanip>
# include <fstream>
# include <sstream>
# include <string>
# include <vector>
# include <ctime>
# include "fuzzymatch.h"

using namespace std;

float duration (const char *label,clock_t start) {
    cerr << setw(14) << label << " "
         << setprecision(4) << (clock() - start)/(float)CLOCKS_PER_SEC
         << "s" << endl;
}

int main(int argc, char *argv[]) {
    FuzzyMatch::Index idx;

    if (argc < 3) {
        cerr << "Usage: " << argv[0] << " <file> <keyword>" << endl;
        return -1;
    }

    std::ifstream fin(argv[1]);
    if (!fin.is_open()) {
        cerr << "Unable to open input file!\n";
        return 0;
    }

    const string target(argv[2]);

    string str;
    clock_t start = clock();
    while (fin >> str);
    duration("load", start);

    std::ifstream fin2(argv[1]);
    start = clock(); 
    while (fin2 >> str)
        // idx.insert(str, new String(str));
        idx.insert(str, NULL);
    duration("load and build", start);

    vector<string> keys;
    start = clock();
    size_t found = idx.match(keys, target);
    duration("find", start);
    cout << "distance: " << found << endl << " matches: ";
    for (vector<string>::iterator it = keys.begin(); it != keys.end(); it++) {
        // string *s = (string *)idx.find(*it)->second;
        // cout << *it << " " << *s << endl;
        cout << *it << " ";
    }
    cout << endl;
}
