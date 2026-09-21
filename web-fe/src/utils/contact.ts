const defaultContactEmail = '41gawor@gmail.com'

export const contactEmail = import.meta.env.VITE_CONTACT_EMAIL?.trim() || defaultContactEmail

export function createMailto(subject: string, body: string): string {
  // Some mail clients do not decode form-style `+` characters as spaces in
  // mailto links, so encode each RFC 6068 query value directly.
  return `mailto:${contactEmail}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`
}
