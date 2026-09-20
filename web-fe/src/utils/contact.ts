const defaultContactEmail = '41gawor@gmail.com'

export const contactEmail = import.meta.env.VITE_CONTACT_EMAIL?.trim() || defaultContactEmail

export function createMailto(subject: string, body: string): string {
  const query = new URLSearchParams({ subject, body })
  return `mailto:${contactEmail}?${query.toString()}`
}
