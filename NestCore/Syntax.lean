import NestCore.TestTree
namespace Nest
namespace Core

declare_syntax_cat nest_tt

scoped syntax "test " str (colGt term) : nest_tt
scoped syntax "group " str (manyIndent(nest_tt)) : nest_tt
scoped syntax "with " " options " term (colGt nest_tt) : nest_tt
scoped syntax "with " " options " " as " ident (colGt nest_tt) : nest_tt
scoped syntax "with " "resource" term " as " ident (colGt nest_tt) : nest_tt

scoped syntax "[nest|" nest_tt "]" : term
macro_rules
| `([nest| test $name:str $texpr:term]) =>
  `(TestTree.single $name $texpr)
| `([nest| group $name:str $[$tests:nest_tt]*]) =>
  `(TestTree.group $name [ $[ [nest|$tests] ],* ])
| `([nest| with options $opt:term $texpr:nest_tt]) =>
  `(TestTree.withOptions $opt [nest| $texpr])
| `([nest| with options as $optId:ident $texpr:nest_tt]) =>
  `(TestTree.getOptions (fun $optId => [nest| $texpr]))
| `([nest| with resource $spec:term as $resId:ident $texpr:nest_tt]) =>
  `(TestTree.withResource $spec (fun $resId => [nest| $texpr]))

end Core
end Nest
