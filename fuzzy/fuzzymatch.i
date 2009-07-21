%module fuzzymatch

%include "attribute.i"
%include "std_string.i"

%apply const std::string& {std::string* foo};

%{
#include "fuzzymatch.h"
%}

%typemap(in) (void *)
{
    $1 = (void *) $input;
}
%typemap(out) (void *)
{
    $result = (VALUE) $1;
}
%typemap(in,numinputs=0) (vector<std::string> &)
{
    vector<std::string> $1_auto;
    $1 = &$1_auto;
}
%typemap(argout) (vector<std::string> &results, const std::string &target)
{
    VALUE found = rb_ary_new();
    VALUE combined; 
    if ($result == FuzzyMatch::Index::not_found) {
        combined = rb_ary_new3(2, Qnil, found);
    } else {
        combined = rb_ary_new3(2, $result, found);
        for (vector<std::string>::iterator $1_it = $1->begin();
             $1_it != $1->end(); $1_it++) {
            rb_ary_push(found, rb_str_new2($1_it->c_str()));
        }
    }
    $result = combined;
}

%typemap(out) FuzzyMatch::Index::iterator {
    if (result == arg1->end())
        $result = Qnil;
    else
        $result = (VALUE) (result->second);
}

%{
    static void mark_FuzzyMatch_index (void *self)
    {
        FuzzyMatch::Index *index = (FuzzyMatch::Index *)self;
        for (FuzzyMatch::Index::iterator it = index->begin();
            it != index->end(); it++) {
            VALUE data = (VALUE)it->second;
            if (data != Qnil)
                rb_gc_mark(data);
        }
    }
%}
%markfunc FuzzyMatch::Index "mark_FuzzyMatch_index";

namespace FuzzyMatch {
    class Index {
        typedef void *iterator;
      public:
        bool insert(const std::string &s, void *d);
        size_t match(vector<std::string> &results, const std::string &target);
        %extend {
            iterator find(const std::string &key) {
                FuzzyMatch::Index::iterator it = self->find(key);
                return it;
            };
        }
    };
};


