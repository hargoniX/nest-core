import NestCore.TestProcessor
import NestCore.TestTree

namespace Nest
namespace Core
namespace Processors

private structure TestRun where
  successes : Nat
  failures : Nat

instance : Add TestRun where
  add a b := ⟨a.successes + b.successes, a.failures + b.failures⟩

/--
A test processor that actually executes the `TestTree` and prints the result
to stdout.
-/
partial def runConsole : TestProcessor where
  relevantOptions := []
  shouldRun? _ := true
  exec opts tests := do
    let run ← go 0 opts tests
    let total := run.failures + run.successes
    if run.failures > 0 then
      IO.println <| boldRed s!"{run.failures} out of {total} tests failed"
      return 1
    else
      IO.println <| boldGreen s!"All {total} tests passed"
      return 0
where
  reset := "\x1b[0m"
  boldRed := fun s => "\x1b[1;31m" ++ s ++ reset
  boldGreen := fun s => "\x1b[1;32m" ++ s ++ reset
  printResult (indent : Nat) (name : String) (res : Result) : IO TestRun := do
    match res.outcome with
    | .success =>
      printPrefix indent <| s!"{name}: " ++ boldGreen "[OK]"
      unless res.details == "" do
        printPrefix (indent + 2) res.details
      return ⟨1, 0⟩
    | .failure reason =>
      match reason with
      | .generic =>
        printPrefix indent <| s!"{name}: {res.shortDescription} " ++ boldRed "[FAIL]"
        unless res.details == "" do
          printPrefix (indent + 2) res.details
      | .io _ =>
        printPrefix indent <| s!"{name}: {res.shortDescription} " ++ boldRed "[ERR]"
        unless res.details == "" do
          printPrefix (indent + 2) res.details
      | .depFailed =>
        printPrefix indent s!"{name}: {res.shortDescription} [SKIPPED] (dependency failed)"
      return ⟨0, 1⟩

  go (indent : Nat) (opts : Options) (tests : TestTree) : IO TestRun := do
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
      return res.foldl (· + ·) ⟨0, 0⟩
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
