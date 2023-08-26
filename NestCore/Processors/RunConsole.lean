import NestCore.TestProcessor
import NestCore.TestTree

namespace Nest
namespace Core
namespace Processors

partial def runConsole : TestProcessor where
  relevantOptions := []
  shouldRun? _ := true
  exec opts tests := go 0 opts tests
where
  printResult (indent : Nat) (name : String) (res : Result) : IO Unit := do
    match res.outcome with
    | .success => printPrefix indent s!"{name}: {res.shortDescription} [OK]"
    | .failure reason =>
      match reason with
      | .generic =>
        printPrefix indent s!"{name}: {res.shortDescription} [FAIL]"
        let details ← res.details
        unless details == "" do
          printPrefix (indent + 2) details
      | .io _ =>
        printPrefix indent s!"{name}: {res.shortDescription} [ERR]"
        let details ← res.details
        unless details == "" do
          printPrefix (indent + 2) details
      | .depFailed =>
        printPrefix indent s!"{name}: {res.shortDescription} [SKIPPED] (dependency failed)"

  go (indent : Nat) (opts : Options) (tests : TestTree) : IO Unit := do
    match tests with
    | .singleInt inst name test =>
      let res ←
        try
          inst.run opts test
        catch e =>
          pure {
            outcome := .failure <| .io e,
            description := "uncaught IO exception from test suite"
            shortDescription := "uncaught IO exception from test suite"
            details := do
              return s!"IO error: {e.toString}"
          }
      printResult indent name res
    | .group name tests =>
      printPrefix indent s!"Running group {name}:"
      tests.forM (go (indent + 2) opts ·)
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
