import { onBeforeUnmount, ref, watch, type Ref } from 'vue'

/**
 * Open/close state for a popover anchored to a trigger.
 *
 * Bind `setRoot` to the element wrapping both the trigger and the panel: a press
 * anywhere outside it closes the popover, as does Escape. The document listeners
 * exist only while it is open, so a closed popover costs nothing.
 */
export function useDismissablePopover(): {
  open: Ref<boolean>
  setRoot: (element: unknown) => void
  toggle: () => void
  close: () => void
} {
  const open = ref(false)
  const root = ref<HTMLElement | null>(null)

  function closeOnOutside(event: MouseEvent): void {
    if (root.value && !root.value.contains(event.target as Node)) open.value = false
  }

  function closeOnEscape(event: KeyboardEvent): void {
    if (event.key === 'Escape') open.value = false
  }

  function detach(): void {
    document.removeEventListener('pointerdown', closeOnOutside)
    document.removeEventListener('keydown', closeOnEscape)
  }

  watch(open, (isOpen) => {
    if (isOpen) {
      document.addEventListener('pointerdown', closeOnOutside)
      document.addEventListener('keydown', closeOnEscape)
    } else {
      detach()
    }
  })

  onBeforeUnmount(detach)

  return {
    open,
    setRoot: (element: unknown) => {
      root.value = element instanceof HTMLElement ? element : null
    },
    toggle: () => { open.value = !open.value },
    close: () => { open.value = false },
  }
}
