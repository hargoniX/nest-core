import NestCore

def Assertion := IO Bool
def assert (bool : Bool) : Assertion := pure bool
def assertIO (bool : IO Bool) : Assertion := bool

def fileRes (path : System.FilePath) (mode : IO.FS.Mode) : Nest.Core.ResourceSpec IO.FS.Handle where
  get := IO.FS.Handle.mk path mode
  release handle := handle.flush
  description := s!"A file handle to {path}"

instance : Nest.Core.IsTest Assertion where
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
def tests : Nest.Core.TestTree :=
  .group "Main Tests" [
    .group "Group 1" [
      .single "assertion 1" (assert true),
      .single "assertion 2" (assert true)
    ],
    .group "Group 2" [
      .withResource (fileRes "/dev/zero" .read) <| fun res => .group s!"With resource" [
        .single "assertion 3" <| assertIO do
          let data ← res.read 12
          return data.size == 12
      ]
    ]
  ]

def main : IO Unit := Nest.Core.defaultMain tests
