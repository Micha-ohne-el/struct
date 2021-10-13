class Struct {
  class Char extends Struct.Member {
    size := 1
    dllType := "Char"
  }
  class Byte extends Struct.Member {
    size := 1
    dllType := "Char"
  }

  class Word extends Struct.Member {
    size := 2
    dllType := "Short"
  }
  class Short extends Struct.Member {
    size := 2
    dllType := "Short"
  }

  class Long extends Struct.Member {
    size := 4
    dllType := "Int"
  }
  class Int extends Struct.Member {
    size := 4
    dllType := "Int"
  }

  class LongLong extends Struct.Member {
    size := 8
    dllType := "Int64"
  }
  class Int64 extends Struct.Member {
    size := 8
    dllType := "Int64"
  }

  class Float extends Struct.Member {
    size := 4
    dllType := "Float"
  }

  class Double extends Struct.Member {
    size := 8
    dllType := "Double"
  }
  class Float64 extends Struct.Member {
    size := 8
    dllType := "Double"
  }

  /*
    Can be used to dynamically set a struct member to the size of the struct.
  */
  static autoSize := (struct) => struct.size


  /*
    Definable Properties:
    * default: (Any, optional)
      The default value that this member should have upon initialization.
    * size: (Integer, optional)
      The size in bytes that the member should take up in the struct.
    * dllType: (String, required)
      The type name that should be used when calling `NumGet`/`NumPut`.
    * alignment: (Integer, optional)
      The aligment to follow when positioning the member.
      If omitted, `size` is used.

    Computed Properties:
    * offset: (Integer)
      Offset into the struct at which this member sits.
  */
  class Member {
    __new(default := "", options := "") {
      if default !== ""
        this.default := default

      ; Flatten the options into this member:
      if options is Object
        for key, value in options.ownProps()
          this.%key% := value
    }
  }

  size => this._buffer.size
  ptr => this._buffer.ptr

  ; Called before members are evaluated:
  __init() {
    ; List of members of the struct:
    this.defineProp "_members", {value: Map()}
    ; Size that the struct should get:
    this.defineProp "_size", {value: 0}
    ; Indicator whether the struct has been initialized:
    this.defineProp "_final", {value: false}
  }

  ; Called after members are evaluated:
  __new() {
    ; Buffer Object that will hold the actual values in memory:
    this.defineProp "_buffer", {value: Buffer(this._size)}
    ; This means no new members can be added, all assignments should now change the value in the struct:
    this.defineProp "_final", {value: true}

    for name, member in this._members {
      for key, value in member.ownProps() {
        member.%key% := this._realize(value)
      }

      if member.hasProp("default") {
        this.%name% := member.default
      }
    }
  }

  __get(name, _) {
    if not this._members.has(name)
      throw propertyError("Unknown member.", -1, name)

    member := this._members.get(name)

    return numGet(this._buffer, member.offset, member.dllType)
  }

  __set(name, _, value) {
    if this._final
      return this._setMember(name, value)
    else
      return this._addMember(name, value)
  }

  _setMember(name, value) {
    if not this._members.has(name)
      throw propertyError("Unknown member.", -1, name)

    member := this._members.get(name)

    numPut member.dllType, value, this._buffer, member.offset
  }

  _addMember(name, member) {
    if not member is Struct.Member
      throw valueError("Members can only be added before initialization", -1)

    if member.hasProp("size") and member.size {
      align := member.hasProp("alignment") ? member.alignment : member.size

      member.offset := this._size + align - (mod(this._size, align) or align)
      this._size := member.offset + member.size
    }

    this._members.set name, member
  }

  ; For allowing functions to be specified in member properties,
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
