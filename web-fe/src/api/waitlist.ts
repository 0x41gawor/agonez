import { postJson } from './client'

interface WaitlistSubmissionResponse {
  accepted: true
}

export function joinWaitlist(email: string, website = '', signal?: AbortSignal): Promise<WaitlistSubmissionResponse> {
  return postJson<WaitlistSubmissionResponse>('/api/waitlist', { email, website }, signal)
}
