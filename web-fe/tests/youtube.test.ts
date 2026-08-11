import { describe, expect, it } from 'vitest'

import { youtubeEmbedUrl, youtubeVideoId } from '@/utils/youtube'

describe('YouTube URL helpers', () => {
  it.each([
    'https://youtu.be/1Z-aEpjdphU?si=abc',
    'https://www.youtube.com/watch?v=1Z-aEpjdphU',
    'https://youtube.com/shorts/1Z-aEpjdphU',
    'https://www.youtube-nocookie.com/embed/1Z-aEpjdphU',
  ])('extracts a video ID from %s', (url) => {
    expect(youtubeVideoId(url)).toBe('1Z-aEpjdphU')
    expect(youtubeEmbedUrl(url)).toBe('https://www.youtube-nocookie.com/embed/1Z-aEpjdphU')
  })

  it.each([
    'https://example.com/watch?v=1Z-aEpjdphU',
    'javascript:alert(1)',
    'https://youtu.be/not-an-id',
  ])('rejects unsupported values', (url) => {
    expect(youtubeVideoId(url)).toBeNull()
    expect(youtubeEmbedUrl(url)).toBeNull()
  })
})
