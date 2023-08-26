import NestCore.TestTree

namespace Nest
namespace Core

/--
Processors are ways in which tests can be run.
-/
structure TestProcessor where
  /--
  The names of options that are relevant to this processor.
  -/
  relevantOptions : List Lean.Name
  /--
  Decide based on `Options` whether this processor should be used.
  -/
  shouldRun? : Options → Bool
  /--
  Run a `TestTree` using `Options` with this processor. The `UInt32`
  in the return value may be used as an exit code for the test program.
  -/
  exec : Options → TestTree → IO UInt32
 
namespace TestProcessor

/--
Run a single `TestProcessor` if it should be run according to `shouldRun?`.
-/
def run? (proc : TestProcessor) (opts : Options) (tests : TestTree) : Option (IO UInt32) := do
  guard <| proc.shouldRun? opts
  return proc.exec opts tests

/--
Run the first `TestProcessor` that wants to run according to `shouldRun?`.
-/
def runFirst? (procs : List TestProcessor) (opts : Options) (tests : TestTree) : Option (IO UInt32) := do
  for proc in procs do
    if proc.shouldRun? opts then
      return proc.exec opts tests
  none

end TestProcessor
 
end Core
end Nest
