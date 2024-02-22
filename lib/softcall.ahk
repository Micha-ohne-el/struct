softcall(function, args*) {
  listLines false

  if function.isVariadic
    args.length := max(args.length, function.minParams)
  else
    args.length := min(max(args.length, function.minParams), function.maxParams)

  ; Replace all empty spots with empty strings, except for optional parameters:
  ; (This is important to catch empty spots in the middle of args.)
  for index, _ in args
    if !args.has(index) && !function.isOptional(index)
      args[index] := ""

  listLines true

  return function(args*)
}
