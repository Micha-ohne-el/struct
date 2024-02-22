#include ../struct.ahk

class Test extends Struct {
  first := Struct.Short(1)
  content := Struct.Array(6, Struct.Word((_, index) => index))
  second := Struct.Word(2)
}

one := Test()

msgbox one.first
msgbox one.content[1]
msgbox one.content[2]
msgbox one.content[3]
msgbox one.content[4]
msgbox one.content[5]
msgbox one.content[6]
msgbox one.second

a::reload
