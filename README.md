# `nest-core`
This is the core library that provides basic infrastructure for the
`nest` testing eco system. The concept is similar to the Haskell library
[`tasty`](https://github.com/UnkindPartition/tasty),
however unlike with `tasty` the test ecosystem was developed around the
core library instead of providing adaptors to already existing frameworks.

This document provides information on how to write tests using `nest`
as well as extending it.

## Basic Structure
Everything in `nest` is based around three types:
- `Nest.Core.TestTree`, this one allows you to specify the hierarchy of tests
- `Nest.Core.IsTest`, this one is a type class which is implemented by other
  libraries like [`nest-unit`](https://github.com/hargonix/nest-unit).
  It allows you to write many different tests like unit tests, property tests,
  golden unit tests etc. using the same framework.
- `Nest.Core.TestProcessor`, this one specifies how to execute a `TestTree`,
  a default executor to just run all of the tests and print their results in
  the console is available from `nest-core`.

## Writing Tests
Since `TestTree` is provided by `nest-core` you only need two things:
- a `TestProcessor` if you are not content with the built-in one
- an `IsTest` implementation, this is provided by external libraries like
  [`nest-unit`](https://github.com/hargonix/nest-unit)

Assuming you have decided to use `nest-unit` here is a full example:
```lean
import NestCore
import NestUnit

open Nest.Core
open Nest.Unit

def fileRes (path : System.FilePath) (mode : IO.FS.Mode) : ResourceSpec IO.FS.Handle where
  get := IO.FS.Handle.mk path mode
  release handle := handle.flush
  description := s!"A file handle to {path}"

def tests : TestTree := [nest|
  group "Self Tests"
    group "Basic"
      test "succeeds on true" : UnitTest := do
        assert true
      test "fails on false (expected to fail)" : UnitTest := do
        assert false
    group "Resource based"
      with resource fileRes "/dev/zero" .read as res
        test "assertion 3" : UnitTest := do
          let data ← res.read 12
          assert data.size = 12
    group "Option based"
      with options fun x => x.insert `Hello "foo"
        with options as x
          test "assertion 4" : UnitTest := do
            assert x.contains `Hello
]

def main : IO UInt32 := Nest.Core.defaultMain tests
```

As you can see `nest-core` provides a scoped syntax extension to write
a `TestTree`. If you wish to write your own `TestTree` without this
extension this is perfectly possible as well since the syntax is just a
very minimal layer on top of the constructors.

Besides just basic groups and tests `nest-core` supports two further primitives
as seen above:
- Resources, these allow you to work with external resources. The above
  example is rather artificial but one could imagine for example a connection
  to a (mock) database, auto generated fake data etc. here. Note that
  `nest-core` guarantees that the `release` function is going to be called.
- Options, they are a `Lean.KVMap` and can be both modified and read by the
  `TestTree`, we do plan on eventually allowing to automatically parse these
  from CLI but at the moment only manual entries can be made.

The `defaultMain` processor is going to use the default console based
test runner to then execute your tests.

## Extending
As explained above there are two points of interest for extending `nest`.

### `IsTest`
Adding new ways to test comes down to writing a new implementation of
the `IsTest` type class. The class itself is quite simple:
```
class IsTest (t : Type) where
  run : Options → t → IO Result
```
As you can see a test run does have access to the `Options` and some
arbitrary data , usually some type that represents the property we wish
to test. In order to test the property it is allowed to run arbitrary
computation in `IO` and finally return a `Result` which is a structure
describing the outcome.

### `TestProcessor`
If you want to change the way that tests are executed, for example providing
a parallel or even distributed runner, one that only prints the results
to files etc. you need to write a `TestProcessor`. They are also quite
basic in structure:
```
structure TestProcessor where
  relevantOptions : List Lean.Name
  shouldRun? : Options → Bool
  exec : Options → TestTree → IO UInt32
```
The
- `relevantOptions` fields tells `nest` which keys in `Options` you are interested in
- `shouldRun?` field is called with the provided options and returns whether to use this processor or not
- `exec` field is used to actually run a `TestTree` and provides a return code via the `UInt32`
  return value.

In order to then inject your own `TestProcessor` into the framework you
want to use `defaultMainWithTestProcessor` instead of `defaultMain` from above. 
