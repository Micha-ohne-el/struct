#include ../struct.ahk

class Rect extends Struct {
  left := Struct.Long(0)
  top := Struct.Long(0)
  right := Struct.Long(0)
  bottom := Struct.Long(0)
}

; Create a new rect and set its values using an initializer:
myRect := Rect({left: 12, top: 34, right: 56, bottom: 78})

msgbox myRect.left    ; 12
msgbox myRect.top     ; 34
msgbox myRect.right   ; 56
msgbox myRect.bottom  ; 78

; Create a copy of the rect:
myOtherRect := myRect.clone()

; Inflate the rect using a DllCall:
dllCall "InflateRect", "Ptr", myOtherRect, "Int", 2, "Int", 2

msgbox myOtherRect.left    ; 12 - 2 = 10
msgbox myOtherRect.top     ; 34 - 2 = 32
msgbox myOtherRect.right   ; 56 + 2 = 58
msgbox myOtherRect.bottom  ; 78 + 2 = 80

; Deflate it again, but this time using AHK:
myOtherRect.left += 2
myOtherRect.top += 2
myOtherRect.right -= 2
myOtherRect.bottom -= 2

; Check that the two rects are equal using DllCall:
if dllCall("EqualRect", "Ptr", myRect, "Ptr", myOtherRect)
  msgbox "Both rects are equal :)"
else
  msgbox "The two rects differ :("
