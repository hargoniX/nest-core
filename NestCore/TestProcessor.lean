import NestCore.TestTree

namespace Nest
namespace Core

structure TestProcessor where
  relevantOptions : List Lean.Name
  shouldRun? : Options → Bool
  exec : Options → TestTree → IO Unit
 
namespace TestProcessor

def run? (proc : TestProcessor) (opts : Options) (tests : TestTree) : Option (IO Unit) := do
  guard <| proc.shouldRun? opts
  return proc.exec opts tests

def runFirst? (procs : List TestProcessor) (opts : Options) (tests : TestTree) : Option (IO Unit) := do
  for proc in procs do
    if proc.shouldRun? opts then
      return proc.exec opts tests
  none

end TestProcessor
 
end Core
end Nest
