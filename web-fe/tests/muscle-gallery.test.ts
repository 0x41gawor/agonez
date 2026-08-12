import { afterEach, describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'

import MuscleGallery from '@/components/detail/MuscleGallery.vue'

const images = Array.from(
  { length: 6 },
  (_, index) => `/media/galleries/muscles/soleus/${index + 1}.png`,
)

afterEach(() => {
  document.body.innerHTML = ''
  document.body.style.overflow = ''
})

describe('MuscleGallery', () => {
  it('shows at most four previews and opens the selected image in a lightbox', async () => {
    const wrapper = mount(MuscleGallery, { props: { images, title: 'Soleus' } })

    const previews = wrapper.findAll('.gallery-preview-item')
    expect(previews).toHaveLength(4)
    expect(previews[3]?.text()).toContain('+2 more')

    await previews[1]?.trigger('click')
    expect(document.querySelector('.gallery-lightbox')).not.toBeNull()
    expect(document.querySelector('.gallery-lightbox')?.textContent).toContain('2 / 6')

    window.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight' }))
    await nextTick()
    expect(document.querySelector('.gallery-lightbox')?.textContent).toContain('3 / 6')

    wrapper.unmount()
  })

  it('leaves modified clicks to the native new-tab link behavior', async () => {
    const wrapper = mount(MuscleGallery, { props: { images, title: 'Soleus' } })

    await wrapper.find('.gallery-preview-item').trigger('click', { ctrlKey: true })
    expect(document.querySelector('.gallery-lightbox')).toBeNull()

    wrapper.unmount()
  })
})
