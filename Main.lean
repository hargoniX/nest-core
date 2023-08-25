import NestCore

open Nest.Core

abbrev TRes := IO Bool
def tres (bool : Bool) : TRes := pure bool

def fileRes (path : System.FilePath) (mode : IO.FS.Mode) : ResourceSpec IO.FS.Handle where
  get := IO.FS.Handle.mk path mode
  release handle := handle.flush
  description := s!"A file handle to {path}"

instance : IsTest TRes where
  run _ assertion := do
    let val ← assertion
    if val then
      return {
        outcome := .success,
        description := "assertion ok",
        shortDescription := "assertion ok"
        detailsPrinter := fun _ => pure ()
      }
    else
      return {
        outcome := .failure .generic,
        description := "assertion failed",
        shortDescription := "assertion failed"
        detailsPrinter := fun _ => pure ()
      }

-- TODO: syntax extension
def tests : TestTree := [nest|
  group "Main Tests"
    group "Group 1"
      test "assertion 1" do
        tres true
      test "assertion 2" do
        tres true
    group "Group 2"
      with resource fileRes "/dev/zero" .read as res
        test "assertion 3" do
          let data ← res.read 12
          tres <| data.size == 12
    group "Group 3"
      with options fun x => x.insert `Hello "foo"
        with options as x
          test "assertion 4"  do
            tres (x.contains `Hello)
]

def main : IO Unit := Nest.Core.defaultMain tests
