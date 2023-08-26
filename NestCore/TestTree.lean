import Lean.Data.KVMap

namespace Nest
namespace Core

/--
A key value map of options passed to the tests
-/
def Options := Lean.KVMap

/--
Why did a test fail?
-/
inductive FailureReason where
/--
Used to indicate a "proper" failure, i.e. that a desired property was violated.
-/
| generic
/--
Currently only used internally to indicate that an `IO.Error` was thrown
from the `TestProcessor`.
-/
| io (error : IO.Error)
/--
Unused until the dependency feature is implemented.
-/
| depFailed

/--
A test outcome.
-/
inductive Outcome where
/--
The test was succesful.
-/
| success
/--
The test failed.
-/
| failure (reason : FailureReason)

/--
Provides details on why a test failed.
-/
abbrev Details := String

/--
Provide a string of `indent` whitespaces.
-/
def indentPrefix (indent : Nat) (str : String := "") : String :=
  match indent with
  | 0 => str
  | n + 1 => indentPrefix n (str ++ " ")

/--
Print `str`, prefixed with `indent` whitespaces>
-/
def printPrefix (indent : Nat) (str : String) : IO Unit :=
  IO.println <| (indentPrefix indent) ++ str

/--
The result of a single test
-/
structure Result where
  /--
  The outcome of the test.
  -/
  outcome : Outcome
  /--
  A description of the test.
  -/
  description : String
  /--
  A short description of the test.
  -/
  shortDescription : String
  /--
  Details on what happened, can be left empty as well
  -/
  details : Details

/--
The core type class for describing what a test is
-/
class IsTest (t : Type) where
  /--
  How to run the test.
  -/
  run : Options → t → IO Result

/--
A specification for a resource that can be acquired for a sub-`TestTree`.
This might for example be a database connection.
-/
structure ResourceSpec (α : Type) where
  /--
  How to obtain the resource.
  -/
  get : IO α
  /--
  How to free the resource after usage.
  -/
  release : α → IO Unit 
  /--
  A description of the resource.
  -/
  description : String

/--
Unused until the dependency feature is implemented.
-/
inductive DependencyType where
| allSucceed
| allFinish 

/--
Describes the layout of tests
-/
inductive TestTree where
/--
This constructor should basically always be ignored in favor of `TestTree.single`.
-/
| singleInt (inst : IsTest t) (name : String) (test : t)
/--
A group of tests under a certain name
-/
| group (name : String) (tests : List TestTree)
/--
Modify the `Options` for this subtree.
-/
| withOptions (f : Options → Options) (x : TestTree)
/--
Acquire a `ResourceSpec` for this subtree.
-/
| withResource (spec : ResourceSpec α) (tests : α → TestTree)
/--
Create a subtree based on the values in `Options`.
-/
| getOptions (tests : Options → TestTree)
/--
Unused until the dependency feature is implemented.
-/
| after (what : DependencyType) (pattern : String) (tests : TestTree)

/--
Describe a single test, this can use any implementation of `IsTest`.
This function should basically always be favored over `TestTree.singleInt`.
-/
def TestTree.single [inst : IsTest t] (name : String) (test : t) : TestTree :=
  .singleInt inst name test

end Core
end Nest
