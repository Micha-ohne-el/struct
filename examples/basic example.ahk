#Include ../struct.ahk

class Rect extends Struct {
  left := Struct.Long()
  top := Struct.Long()
  right := Struct.Long()
  bottom := Struct.Long()
}

; Create a new rect and set its values using a DllCall:

myRect := Rect()

dllCall("SetRect", "Ptr", myRect, "Int", 12, "Int", 34, "Int", 56, "Int", 78)

; Confirm that the values are correctly set and can be accessed through AHK:

msgBox myRect.left   ; 12
msgBox myRect.top    ; 34
msgBox myRect.right  ; 56
msgBox myRect.bottom ; 78

; Clone the rect and inflate it by 2 units in each direction:

myOtherRect := Rect()

dllCall("CopyRect", "Ptr", myOtherRect, "Ptr", myRect)

dllCall("InflateRect", "Ptr", myOtherRect, "Int", 2, "Int", 2)

; Confirm; Top and Left should have gone down, and Bottom and Right up:

msgBox myOtherRect.left    ; 10
msgBox myOtherRect.top     ; 32
msgBox myOtherRect.right   ; 58
msgBox myOtherRect.bottom  ; 80

; Deflate it again, but this time using AHK:

myOtherRect.left += 2
myOtherRect.top += 2
myOtherRect.right -= 2
myOtherRect.bottom -= 2

; Check that the two rects are equal again:

if dllCall("EqualRect", "Ptr", myRect, "Ptr", myOtherRect)
  msgBox "Both rects are equal again!"
