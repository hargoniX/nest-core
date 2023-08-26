import Lean.Data.KVMap

namespace Nest
namespace Core

def Options := Lean.KVMap

inductive FailureReason where
| generic
| io (error : IO.Error)
| depFailed

inductive Outcome where
| success
| failure (reason : FailureReason)

def Details := IO String

def indentPrefix (indent : Nat) (str : String := "") : String :=
  match indent with
  | 0 => str
  | n + 1 => indentPrefix n (str ++ " ")

def printPrefix (indent : Nat) (str : String) : IO Unit :=
  IO.println <| (indentPrefix indent) ++ str

structure Result where
  outcome : Outcome
  description : String
  shortDescription : String
  details : Details

class IsTest (t : Type) where
  run : Options → t → IO Result

structure ResourceSpec (α : Type) where
  get : IO α
  release : α → IO Unit 
  description : String

inductive DependencyType where
| allSucceed
| allFinish 

inductive TestTree where
| singleInt (inst : IsTest t) (name : String) (test : t)
| group (name : String) (tests : List TestTree)
| withOptions (f : Options → Options) (x : TestTree)
| withResource (spec : ResourceSpec α) (tests : α → TestTree)
| getOptions (tests : Options → TestTree)
| after (what : DependencyType) (pattern : String) (tests : TestTree)

def TestTree.single [inst : IsTest t] (name : String) (test : t) : TestTree :=
  .singleInt inst name test

end Core
end Nest
