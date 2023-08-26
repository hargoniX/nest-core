import NestCore.TestProcessor
import NestCore.TestTree

namespace Nest
namespace Core
namespace Processors

/--
A test processor that actually executes the `TestTree` and prints the result
to stdout.
-/
partial def runConsole : TestProcessor where
  relevantOptions := []
  shouldRun? _ := true
  exec opts tests := go 0 opts tests
where
  printResult (indent : Nat) (name : String) (res : Result) : IO UInt32 := do
    match res.outcome with
    | .success =>
      printPrefix indent s!"{name}: {res.shortDescription} [OK]"
      return 0
    | .failure reason =>
      match reason with
      | .generic =>
        printPrefix indent s!"{name}: {res.shortDescription} [FAIL]"
        unless res.details == "" do
          printPrefix (indent + 2) res.details
      | .io _ =>
        printPrefix indent s!"{name}: {res.shortDescription} [ERR]"
        unless res.details == "" do
          printPrefix (indent + 2) res.details
      | .depFailed =>
        printPrefix indent s!"{name}: {res.shortDescription} [SKIPPED] (dependency failed)"
      return 1

  go (indent : Nat) (opts : Options) (tests : TestTree) : IO UInt32 := do
    match tests with
    | .singleInt inst name test =>
      try
        let res ← inst.run opts test
        printResult indent name res
      catch e =>
        let res := {
          outcome := .failure <| .io e,
          description := "uncaught IO exception from test suite"
          shortDescription := "uncaught IO exception from test suite"
          details := "IO error: {e.toString}"
        }
        printResult indent name res
    | .group name tests =>
      printPrefix indent s!"Running group {name}:"
      let res ← tests.mapM (go (indent + 2) opts ·)
      if res.find? (· != 0) |>.isSome then
        return 1
      else
        return 0
    | .withOptions f x => go indent (f opts) x
    | .withResource spec tests =>
      printPrefix indent s!"Acquiring resource: {spec.description}"
      let resource ← spec.get
      try
        go (indent + 2) opts (tests resource)
      finally
        printPrefix indent s!"Releasing resource"
        spec.release resource
    | .getOptions tests => go indent opts (tests opts)
    | .after .. => throw <| IO.userError "after is not implemented"


end Processors
end Core
end Nest
