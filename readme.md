# Struct

Model C/C++ structs with plain AutoHotkey classes.

## Current state of the project

Basic features are usable, but more complex stuff is not.
Primitive fields work as they should, but pointers and strings are missing (both relatively easy to implement though).
Arrays work.
Unions work.
You can nest arrays inside of unions (not much testing done here though), but unions inside arrays doesn't work right now (I know why but it's not a trivial fix (or my brain is too mush)).
`Struct.autoSize` works great.
Structs generally always seem to get the right size and the right alignment.

## Usage

See the `examples` folder.

Create a subclass of `Struct`, then assign `Struct.Field`s to any properties you like. The order determines the order of the fields.

```ahk
class MyStruct extends Struct {
  myField := Struct.Char()
  myOtherField := Struct.Double()
}
```

Assigning to the properties after the constructor has been called works completely differently, it now sets the value of the field.

```ahk
; ... continuing from above

test := MyStruct()

test.myField := 123
test.myOtherField := 123.456 ; note: I think I never tested float values lmao
```

Each `Struct.Field` can receive a default value as its first constructor argument, so that you can initialize fields immediately (i.e. `name := Struct.Char(123)` creates a CHAR/BYTE member initialized with the value `123`).
This value can be a function, which is called _after all fields have been determined_ (i.e. when calling the constructor).
The function is passed the instance of the struct.
This is exactly how `Struct.autoSize` works. If you check its implementation, it's literally just a function that returns the struct's size.
So you can do `name := Struct.Word(Struct.autoSize)` to have that member automatically be initialized with the struct's final size.

Omitting the default value of any field leaves the allocated memory _uninitialized_ (garbage data).

Fields also take a second constructor argument, which is just an object to override any property of the field (such as size, alignment, etc.). Should be rarely useful.

Arrays take two arguments, first a length and then a field. The field can have a default value, in which case the entire array is initialized with that value.
Nesting arrays may or may not work (I doubt it), I haven't tested that at all.

```ahk
class MyStruct extends Struct {
  myArrayField := Struct.Array(16, Struct.Char())
  myOtherArrayField := Struct.Array(100, Struct.Long(123))
}
```

To access an array field, you should index it (i.e. `myStruct.myArrayField[1]`). Simply accessing it technically works but kinda exposes the underlying field, which isn't super great. `myStruct.myArrayField` does _not_ return an AHK array. Enumeration is supported though (for-loops).

Unions take any amount of fields. The size of the union is the size of the largest field. Only one field can have a default value.

```ahk
class MyStruct extends Struct {
  myUnionField := Struct.Union(
    Struct.Char(), ; fun fact: commas can be ommitted here because ahk is just quirky like that
    Struct.Long()
  )
}
```

To access a union field, you need to index it with the type you want to read it as. For example: `myStruct.myUnionField[Struct.Char]`. This type must match one of the declared types. In the same way you can also assign a value to it: `myStruct.myUnionField[Struct.Word] := 1234567`.
Alternatively you can do this: `myStruct.myUnionField := Struct.Word(1234567)`.

You can put arrays inside unions, but unions inside of arrays don't work as of now. Unions inside of unions _should_ work but I wouldn't bet on it haha.

When instantiating a struct, you can provide an initializer:

```ahk
class Rect extends Struct {
  left := Struct.Long(0)
  top := Struct.Long(0)
  right := Struct.Long(0)
  bottom := Struct.Long(0)
}

myRect := Rect({left: 12, top: 34, right: 56, bottom: 78})
```

Omitting values here is fine.

This does work for initializing unions (you would pass an instance of a field as one of the values), and also for arrays (pass an AHK array of the same length and the values will be correctly assigned), but it does not work for arrays inside of unions.

You can also clone an existing instance with `myInstance.clone()`. You can also pass an initializer here, it works exactly the same way as in the constructor.

Big bummer: You can't currently use a struct as a field in another struct. Somehow I completely forgot that this is a thing and everything is made in a way where this is actually pretty difficult to hack in. If I ever rewrite this (for the forth time then haha) then I will fix it (pinky promise).
