#include ../struct.ahk

class Test extends Struct {
  first := Struct.Short(1)
  content := Struct.Union(
    Struct.Array(2, Struct.Char()),
    Struct.Short(256)
  )
  second := Struct.Short(2)
}

whatever := Test()

msgbox whatever.size

msgbox whatever.first
msgbox whatever.content[Struct.Array][1]
msgbox whatever.content[Struct.Array][2]
msgbox whatever.content[Struct.Short]
msgbox whatever.second

whatever.content := Struct.Array(2, Struct.Char(1))
