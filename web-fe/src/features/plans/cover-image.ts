/**
 * Preparation of a plan cover image in the browser.
 *
 * The picture an athlete picks is usually a phone photo of several megabytes, while
 * the cover is never drawn larger than a card. Downscaling here keeps the upload far
 * below the API's limit, so the size cap is a guard against odd input rather than
 * something a normal photo runs into.
 */

/** The longest edge a stored cover needs; cards and the editor draw it much smaller. */
export const COVER_MAX_EDGE = 960
const COVER_QUALITY = 0.86

export class CoverImageError extends Error {}

/** Fit the image inside a square of `maxEdge`, never enlarging a smaller picture. */
export function coverDimensions(
  width: number,
  height: number,
  maxEdge: number = COVER_MAX_EDGE,
): { width: number; height: number } {
  const longest = Math.max(width, height)
  if (longest <= maxEdge) return { width, height }
  const scale = maxEdge / longest
  return {
    width: Math.max(1, Math.round(width * scale)),
    height: Math.max(1, Math.round(height * scale)),
  }
}

async function encode(canvas: HTMLCanvasElement): Promise<Blob> {
  // WebP first; a browser that cannot encode it silently hands back a PNG, which the
  // API also accepts, so the upload still succeeds.
  const blob = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, 'image/webp', COVER_QUALITY),
  )
  if (blob) return blob
  const fallback = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, 'image/jpeg', COVER_QUALITY),
  )
  if (!fallback) throw new CoverImageError('The picture could not be encoded')
  return fallback
}

export async function prepareCoverImage(file: File): Promise<Blob> {
  if (!file.type.startsWith('image/')) {
    throw new CoverImageError('The chosen file is not an image')
  }
  const bitmap = await createImageBitmap(file)
  try {
    const { width, height } = coverDimensions(bitmap.width, bitmap.height)
    const canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    const context = canvas.getContext('2d')
    if (!context) throw new CoverImageError('The picture could not be prepared')
    context.drawImage(bitmap, 0, 0, width, height)
    return await encode(canvas)
  } finally {
    bitmap.close()
  }
}
