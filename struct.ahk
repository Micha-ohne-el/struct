class Struct {
  class Byte extends Struct.Member {
    size := 1
    dllType := "Char"
  }

  class Short extends Struct.Member {
    size := 2
    dllType := "Short"
  }

  class Int extends Struct.Member {
    size := 4
    dllType := "Int"
  }

  class Int64 extends Struct.Member {
    size := 8
    dllType := "Int64"
  }

  class Float extends Struct.Member {
    size := 4
    dllType := "Float"
  }

  class Float64 extends Struct.Member {
    size := 8
    dllType := "Double"
  }


  /*
    Definable Properties:
    * default: (Any)
      The default value that this member should have upon initialization.
    * size: (Integer)
      The size in bytes that the member should take up in the struct.
    * dllType: (String)
      The type name that should be used when calling `NumGet`/`NumPut`.
    * alignment: (Integer)
      The aligment to follow when positioning the member.
      If omitted, `size` is used.

    Computed Properties:
    * offset: (Integer) Offset into the struct at which this member sits.
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
}
