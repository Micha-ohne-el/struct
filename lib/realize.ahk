#include ./softcall.ahk

realize(value, args*) {
  if value is Func
    return softcall(value, args*)
  else
    return value
}

realizeObject(&object, args*) {
  for key, value in object.ownProps()
    object.%key% := realize(value, args*)
}
