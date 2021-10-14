class Struct {
  class Char extends Struct.Field {
    size := 1
    type := "Char"
  }
  class Byte extends Struct.Field {
    size := 1
    type := "Char"
  }

  class Word extends Struct.Field {
    size := 2
    type := "Short"
  }
  class Short extends Struct.Field {
    size := 2
    type := "Short"
  }

  class Long extends Struct.Field {
    size := 4
    type := "Int"
  }
  class Int extends Struct.Field {
    size := 4
    type := "Int"
  }

  class LongLong extends Struct.Field {
    size := 8
    type := "Int64"
  }
  class Int64 extends Struct.Field {
    size := 8
    type := "Int64"
  }

  class Float extends Struct.Field {
    size := 4
    type := "Float"
  }

  class Double extends Struct.Field {
    size := 8
    type := "Double"
  }
  class Float64 extends Struct.Field {
    size := 8
    type := "Double"
  }

  /*
    Can be used to dynamically set a field to the size of the struct.
  */
  static autoSize := (struct) => struct.size


  /*
    Definable Properties:
    * default: (Any, optional)
      The default value that this field should have upon initialization.
    * size: (Integer, optional)
      The size in bytes that the field should take up in the struct.
    * type: (String, required)
      The type name that should be used when calling `NumGet`/`NumPut`.
    * alignment: (Integer, optional)
      The aligment to follow when positioning the field.
      If omitted, `size` is used.

    Computed Properties:
    * offset: (Integer)
      Offset into the struct at which this field sits.
  */
  class Field {
    __new(default := "", options := "") {
      if default !== ""
        this.default := default

      ; Flatten the options into this object:
      if options is Object
        for key, value in options.ownProps()
          this.%key% := value
    }
  }

  size => this._buffer.size
  ptr => this._buffer.ptr

  ; Called before fields are evaluated:
  __init() {
    ; List of fields of the struct:
    this.defineProp "_fields", {value: Map()}
    ; Size that the struct should get:
    this.defineProp "_size", {value: 0}
    ; Alignment of the struct (equals the largest alignment of all members):
    this.defineProp "_alignment", {value: 0}
    ; Indicator whether the struct has been initialized:
    this.defineProp "_final", {value: false}
  }

  ; Called after fields are evaluated:
  __new(initializer := "") {
    ; Pad the end of the struct to match this._alignment:
    this._size += this._alignment - (mod(this._size, this._alignment) or this._alignment)

    ; Buffer Object that will hold the actual values in memory:
    this.defineProp "_buffer", {value: Buffer(this._size)}
    ; This means no new fields can be added, all assignments should now change the value in the struct:
    this.defineProp "_final", {value: true}

    for name, field in this._fields {
      for key, value in field.ownProps() {
        field.%key% := this._realize(value)
      }

      if initializer.hasProp(name) {
        this.%name% := initializer.%name%
      }
      else if field.hasProp("default") {
        this.%name% := field.default
      }
    }
  }

  __get(name, _) {
    if not this._fields.has(name)
      throw propertyError("Unknown field.", -1, name)

    field := this._fields.get(name)

    return numGet(this._buffer, field.offset, field.type)
  }

  __set(name, _, value) {
    if this._final
      return this._setField(name, value)
    else
      return this._addField(name, value)
  }

  _setField(name, value) {
    if not this._fields.has(name)
      throw propertyError("Unknown field.", -1, name)

    field := this._fields.get(name)

    numPut field.type, value, this._buffer, field.offset
  }

  _addField(name, field) {
    if not field is Struct.Field
      throw valueError("Fields can only be added before initialization", -1)

    if field.hasProp("size") and field.size {
      align := field.hasProp("alignment") ? field.alignment : field.size
      this._alignment := max(this._alignment, align)

      field.offset := this._size + align - (mod(this._size, align) or align)
      this._size := field.offset + field.size
    }

    this._fields.set name, field
  }

  ; For allowing functions to be specified in field properties,
  ; instead of real values:
  _realize(value) {
    if value is Func
      return Struct._safecall(value, this)
    else
      return value
  }

  /*
    Source: https://github.com/Micha-ohne-el/safecall
  */
  static _safecall(function, args*) {
    if not function is Func
      throw valueError("Parameter #1 (function) must be of type Func.", -1)

    ; Set the args array length to the correct value:
    if function.isVariadic
      args.length := max(args.length, function.minParams)
    else
      args.length := min(max(args.length, function.minParams), function.maxParams)

    ; Replace all empty spots with empty strings, except for optional parameters:
    ; (This is important to catch empty spots in the middle of args.)
    for index, _ in args
      if not args.has(index) and not function.isOptional(index)
        args[index] := ""

    return function(args*)
  }
}
