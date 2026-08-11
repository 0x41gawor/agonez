import { describe, expect, it } from 'vitest'

import { buildQuery } from '@/api/client'
import { apiUrl, mediaUrl } from '@/api/url'

describe('Atlas query and URL helpers', () => {
  it('serializes repeatable filters as repeated keys', () => {
    expect(buildQuery({ body_part: ['Upper', 'Core'], page: 2, q: 'press' })).toBe(
      '?body_part=Upper&body_part=Core&page=2&q=press',
    )
  })

  it('omits empty values while retaining zero and false', () => {
    expect(buildQuery({ q: '', unused: undefined, page: 0, enabled: false })).toBe('?page=0&enabled=false')
  })

  it('keeps relative API and media paths same-origin by default', () => {
    expect(apiUrl('/api/atlas/meta')).toBe('/api/atlas/meta')
    expect(mediaUrl('/media/muscles/soleus.png')).toBe('/media/muscles/soleus.png')
    expect(mediaUrl(null)).toBeNull()
  })
})
