/// True when the provider raised the master's "not found" sentinel.
///
/// Detail providers (`clEventDetailProvider`, `clVenueDetailProvider`, …)
/// raise `StateError('<Entity> X not found in master')` when the row is
/// absent from the master map (deleted server-side, or never existed). We
/// use the message text as the marker because the providers don't yet
/// throw a dedicated exception class — once they do, this check should
/// switch to a type test.
bool isMasterNotFoundError(Object error) {
  return error is StateError && error.message.contains('not found in master');
}
