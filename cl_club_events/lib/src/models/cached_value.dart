/// Cached value wrapper for AsyncNotifier state preservation.
/// Preserves last good data during loading and error states to prevent UI
/// flashing.
typedef CachedValue<T> = ({T? data, Object? error, bool isLoading});
