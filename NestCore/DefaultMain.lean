import NestCore.TestProcessor
import NestCore.Processors

namespace Nest
namespace Core

/--
Run the first `TestProcessor` that wants to be run, if none volunteers throw an exception.
-/
def defaultMainWithTestProcessor (procs : List TestProcessor) (tests : TestTree) : IO UInt32 := do
  -- TODO: get from command line
  let opts := .empty
  match TestProcessor.runFirst? procs opts tests with
  | none =>
    let err := "No test processor tried to run, either the test suite or the options are malformed"
    throw <| IO.userError err
  | some act => act

/--
The built-in `TestProcessor`s used by `defaultMain`.
-/
def defaultTestProcessors : List TestProcessor := [Processors.list, Processors.runConsole]

/--
Execute a `TestTree` using the `defaultTestProcessors` through `defaultMainWithTestProcessor`.
-/
def defaultMain (tests : TestTree) : IO UInt32 :=
  defaultMainWithTestProcessor defaultTestProcessors tests

end Core
end Nest
