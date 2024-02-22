#requires AutoHotkey v2.0

#include ../lib/softcall.ahk
#include ../lib/realize.ahk

class Struct {
  class Char extends Struct.Field {
    size := 1
    type := "Char"
  }
  class Byte extends Struct.Char {
  }

  class Word extends Struct.Field {
    size := 2
    type := "Short"
  }
  class Short extends Struct.Word {
  }

  class Int extends Struct.Field {
    size := 4
    type := "Int"
  }
  class Long extends Struct.Int {
  }

  class Int64 extends Struct.Field {
    size := 8
    type := "Int64"
  }
  class LongLong extends Struct.Int64 {
  }

  class Float extends Struct.Field {
    size := 4
    type := "Float"
  }

  class Float64 extends Struct.Field {
    __new(args*) {
      super.__new(args*)
      ;this.base := Struct.Double.prototype
    }

    size := 8
    type := "Double"
  }
  class Double extends Struct.Float64 {
  }

  class Array extends Struct.Field {
    __new(length, field) {
      this.length := length
      this.field := field
      this.size := field.size * length

      if field.hasProp("default")
        this.default := field.default
    }

    get(_struct) {
      return this
    }

    set(_struct, value, args) {
      if args.length == 0
        this._setAll(value)
      else if args.length == 1
        this[args[1]] := value
      else
        throw IndexError("Only 0 or 1 indices are supported.", -1)
    }

    _setAll(arr) {
      if arr.length != this.length
        throw IndexError("Assigned array's length must match amount of members.", -1)

      for index, value in arr
        this[index] := value
    }

    initialize(_struct) {
      this._struct := _struct

      if this.field.hasProp("default")
        loop this.length
          this[A_Index] := realize(this.field.default, _struct, A_Index)
    }

    alignment => this.field.size

    __item[index] {
      get {
        this.field.offset := this.offset + this.field.size * (index - 1)

        return this.field.get(this._struct)
      }

      set {
        this.field.offset := this.offset + this.field.size * (index - 1)

        this.field.set(this._struct, value)
      }
    }

    __enum(numberOfVars) {
      switch (numberOfVars) {
        case 1:
          return Struct.Array.ValuesIterator(this)
        case 2:
          return Struct.Array.EntriesIterator(this)
        default:
          throw Error("Only two iteration variables are supported.", -1)
      }
    }

    class ValuesIterator {
      __new(array) {
        this.array := array
      }

      index := 1

      call(&value) {
        if this.index > this.array.length
          return false

        value := this.array[this.index]

        this.index++

        return true
      }
    }

    class EntriesIterator {
      __new(array) {
        this.array := array
      }

      index := 1

      call(&index, &value) {
        if this.index > this.array.length
          return false

        index := this.index
        value := this.array[this.index]

        this.index++

        return true
      }
    }
  }

  class Union extends Struct.Field {
    __new(members*) {
      for member in members {
        if not member is Struct.Field
          throw Error("Only Struct.Field subtypes are valid union members.", -1, member)

        if member.hasProp("default") {
          if this.hasProp("defaultMember")
            throw Error("Only one member of a union can have a default value.", -1, member.default)

          this.defaultMember := member
        }

        if member.size > this.size
          this.size := member.size
      }

      this._members := members
    }

    initialize(_struct) {
      this._struct := _struct

      for member in this._members {
        member.offset := this.offset + (this.size - member.size)
        member.initialize(_struct)
      }

    }

    get(_struct) {
      return this
    }

    set(_struct, value, args) {
      if args.length == 1
        this[args[1]] := value
      else if value is Struct.Field
        this[value.base] := value.default
      else
        throw Error("To set a union's value, pass the desired type in square brackets or assign an instance of Struct.Field.", -2)
    }

    __item[memberClassOrPrototype] {
      get {
        member := this._findMember(memberClassOrPrototype)
        return member.get(this._struct)
      }

      set {
        member := this._findMember(memberClassOrPrototype)
        member.set(this._struct, value)
      }
    }

    _findMember(memberClassOrPrototype) {
      if memberClassOrPrototype is Class
        memberPrototype := memberClassOrPrototype.prototype
      else
        memberPrototype := memberClassOrPrototype

      if !hasBase(memberPrototype, Struct.Field.prototype)
        throw Error("Only Struct.Field subtypes are valid union members.", -2)

      for member in this._members {
        if hasBase(member, memberPrototype)
          return member
      }

      throw Error("Union does not contain member of type " memberPrototype.__class ".", -2)
    }
  }

  static autoSize := (_struct) => _struct.size


  size => this._buffer.size
  ptr => this._buffer.ptr

  clone(initializer?) {
    obj := %this.__class%(this)

    if isSet(initializer)
      obj._initializeFields(initializer)

    return obj
  }

  hasOwnProp(name) {
    return this._fields.has(name)
  }

  __init() {
    ; The Map of name to Field of all of this struct's fields:
    this.defineProp "_fields", {value: Map()}

    ; The total size of this struct:
    this.defineProp "_size", {value: 0}

    ; The total alignment of this struct (equal to the largest alignment out of all members):
    this.defineProp "_alignment", {value: 0}

    ; Whether new fields can still be added to the struct (false) or assignments should only change existing fields (true):
    this.defineProp "_isFinalized", {value: false}
  }

  __new(initializer?) {
    ; Pad the end of the struct to match this._alignment:
    this._size += this._alignment - (mod(this._size, this._alignment) or this._alignment)

    ; The Buffer that will hold the actual value in memory:
    this.defineProp "_buffer", {value: Buffer(this._size)}

    ; No new fields may be added, all future assignments should change the values of the fields, not add new ones:
    this.defineProp "_isFinalized", {value: true}

    this._initializeFields(initializer?)
  }

  _initializeFields(initializer?) {
    for name, field in this._fields {
      realizeObject(&field, this)

      field.initialize(this)

      if isSet(initializer) && initializer.hasOwnProp(name)
        this.%name% := initializer.%name%
    }
  }

  __get(name, args) {
    if not this._fields.has(name)
      throw PropertyError("Unknown field.",, name)

    field := this._fields.get(name)

    if args.length == 0
      return softcall(field.get, field, this)
    else
      return softcall(field.get, field, this)[args*]
  }

  __set(name, args, value) {
    if this._isFinalized
      return this._setField(name, value, args)
    else
      return this._addField(name, value)
  }

  _setField(name, value, args) {
    if not this._fields.has(name)
      throw PropertyError("Unknown field.",, name)

    field := this._fields.get(name)

    softcall(field.set, field, this, realize(value, this), args)
  }

  _addField(name, field) {
    if not field is Struct.Field
      throw ValueError("Field values must be set after initialization of the struct, or by using a default field value.",, name)

    if field.size
      this._resizeFor(field)

    this._fields.set(name, field)
  }

  _resizeFor(field) {
    alignment := field.alignment
    this._alignment := max(this._alignment, alignment)

    field.offset := this._size + alignment - (mod(this._size, alignment) or alignment)
    this._size := field.offset + field.size
  }

  /**
    @property default The default value for the field.
    @property size The size (in bytes) of the field.
    @property alignment The amount of bytes this field is aligned by (defaults to `size`).
  */
  class Field {
    __new(default?, options := {}) {
      if isSet(default)
        this.default := default

      for key, value in options.ownProps()
        this.defineProp(key, {value: value}) ; not regular assignment to allow overriding alignment (normally read-only).
    }

    size := 0

    alignment => this.size

    get(_struct) {
      return numGet(_struct._buffer, this.offset, this.type)
    }

    set(_struct, value) {
      numPut this.type, value, _struct._buffer, this.offset
    }

    initialize(_struct) {
      if this.hasProp("default")
        this.set(_struct, this.default)
    }
  }
}
