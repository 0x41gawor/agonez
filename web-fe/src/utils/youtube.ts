const YOUTUBE_ID = /^[A-Za-z0-9_-]{11}$/
const YOUTUBE_HOSTS = new Set([
  'youtube.com',
  'www.youtube.com',
  'm.youtube.com',
  'music.youtube.com',
  'youtube-nocookie.com',
  'www.youtube-nocookie.com',
])

export function youtubeVideoId(value: string): string | null {
  try {
    const url = new URL(value)
    if (url.protocol !== 'http:' && url.protocol !== 'https:') return null

    const parts = url.pathname.split('/').filter(Boolean)
    let id: string | null = null
    if ((url.hostname === 'youtu.be' || url.hostname === 'www.youtu.be') && parts.length) {
      id = parts[0] ?? null
    } else if (YOUTUBE_HOSTS.has(url.hostname)) {
      if (url.pathname.replace(/\/$/, '') === '/watch') id = url.searchParams.get('v')
      else if (parts.length >= 2 && ['embed', 'live', 'shorts'].includes(parts[0] ?? '')) id = parts[1] ?? null
    }
    return id && YOUTUBE_ID.test(id) ? id : null
  } catch {
    return null
  }
}

export function youtubeEmbedUrl(value: string): string | null {
  const id = youtubeVideoId(value)
  return id ? `https://www.youtube-nocookie.com/embed/${id}` : null
}
