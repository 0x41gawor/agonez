import { onScopeDispose, ref, watch, type Ref } from 'vue'

export function useDebouncedValue<T>(source: Ref<T>, delay = 250): Ref<T> {
  const value = ref(source.value) as Ref<T>
  let timer: ReturnType<typeof setTimeout> | undefined
  watch(source, (next) => {
    clearTimeout(timer)
    timer = setTimeout(() => {
      value.value = next
    }, delay)
  })
  onScopeDispose(() => clearTimeout(timer))
  return value
}
