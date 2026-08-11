import { apiUrl } from './url'

let anatomyRequest: Promise<string> | null = null

export function fetchAnatomySource(): Promise<string> {
  anatomyRequest ??= fetch(apiUrl('/assets/anatomy.svg'))
    .then((response) => {
      if (!response.ok) throw new Error('Anatomy SVG unavailable')
      return response.text()
    })
    .catch((error: unknown) => {
      anatomyRequest = null
      throw error
    })
  return anatomyRequest
}
