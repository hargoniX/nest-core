import NestCore.TestProcessor
import NestCore.Processors

namespace Nest
namespace Core

def defaultMainWithTestProcessor (procs : List TestProcessor) (tests : TestTree) : IO UInt32 := do
  -- TODO: get from command line
  let opts := .empty
  match TestProcessor.runFirst? procs opts tests with
  | none =>
    let err := "No test processor tried to run, either the test suite or the options are malformed"
    throw <| IO.userError err
  | some act => act

def defaultTestProcessors : List TestProcessor := [Processors.list, Processors.runConsole]

def defaultMain (tests : TestTree) : IO UInt32 :=
  defaultMainWithTestProcessor defaultTestProcessors tests

end Core
end Nest
