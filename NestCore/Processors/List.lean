import NestCore.TestProcessor
import NestCore.TestTree

namespace Nest
namespace Core
namespace Processors

partial def list : TestProcessor where
  relevantOptions := [`list]
  shouldRun? opts := opts.findD `list false |>.getBoolEx
  exec opts tests := do
    go 0 opts tests
    return 0
where
  go (indent : Nat) (opts : Options) (tests : TestTree) : IO Unit := do
    match tests with
    | .singleInt _ name _ => printPrefix indent s!"test: {name}"
    | .group name tests =>
      printPrefix indent s!"group: {name}"
      tests.forM (go (indent + 2) opts ·)
    | .withOptions f x => go (indent + 2) (f opts) x
    | .withResource spec tests =>
      printPrefix indent s!"Using resource: {spec.description}"
      let resource ← spec.get
      try
        go (indent + 2) opts (tests resource)
      finally
        spec.release resource
    | .getOptions tests => go indent opts (tests opts)
    | .after what pattern tests =>
      let whatStr :=
        match what with
        | .allSucceed => "all succeeded"
        | .allFinish => "all finished"
      printPrefix indent s!"only run after: {pattern} have {whatStr}"
      go (indent + 2) opts tests


end Processors
end Core
end Nest
