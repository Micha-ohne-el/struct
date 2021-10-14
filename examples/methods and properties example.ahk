#include ../struct.ahk

class Rect extends Struct {
  left := Struct.Long()
  top := Struct.Long()
  right := Struct.Long()
  bottom := Struct.Long()

  ; You can define properties on a struct:
  width => this.right - this.left
  height => this.bottom - this.top

  ; You can define methods on a struct:
  shift(x, y) {
    this.left += x
    this.right += x
    this.top += y
    this.bottom += y
  }

  ; Static properties and methods are also allowed:
  static equal(a, b) {
    return dllCall("EqualRect", "Ptr", a, "Ptr", b)
  }

  ; A custom constructor *must* call `super.__new()`:
  __new(args*) {
    super.__new(args*)

    msgBox "A Rect has been created!"
  }
}

rect1 := Rect({
  left:   12,
  top:    34,
  right:  56,
  bottom: 78
}) ; A Rect has been created!

rect2 := Rect({
  left:   112,
  top:    134,
  right:  156,
  bottom: 178
}) ; A Rect has been created!

msgBox rect1.width == rect2.width ; True (1)
msgBox rect1.height == rect2.height ; True (1)
msgBox Rect.equal(rect1, rect2) ; False (0)

rect2.shift(-100, -100)

msgBox Rect.equal(rect1, rect2) ; True (1)
