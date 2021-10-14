#include ../struct.ahk

class Rect extends Struct {
  left := Struct.Long()
  top := Struct.Long()
  right := Struct.Long()
  bottom := Struct.Long()
  structSize := Struct.Char(Struct.autoSize)
}

r := Rect()

msgBox r.structSize ; 4 + 4 + 4 + 4 + 1 + 3 bytes of padding = 20
