# Development/code style rules

## Limitations

- `eval` and `bool_eval?` must only be called by the code
  entrypoint, or from another `eval` or `bool_eval?`.
  It must NOT be called during initialization,
  `unwrap`-methods, or any other method not explicitly
  permitted. Doing so may is likely to cause issues, for
  instance it could result in eval'ing a variable that has
  not yet been defined in the scope.
- `bool_eval?` should only return literal ruby booleans.
- `eval` should only return objects that inherit `BaseNode`.

## Code style

- `then` should be avoided.
