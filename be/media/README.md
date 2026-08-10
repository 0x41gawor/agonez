# Media layout

The API serves this tree at `/media` when `MEDIA_ROOT=./media`.

```text
media/
  anatomy.svg
  exercises/
    dragon_flag.png
    {exercise_slug}.{avif|webp|png|jpg|jpeg}
  muscles/
    latissimus_dorsi.webp
    {muscle_slug}.{avif|webp|png|jpg|jpeg}
    latissimus_dorsi/
      01-origin.webp
      02-insertion.webp
```

The first supported extension found in the order AVIF, WebP, PNG, JPG, JPEG is used as
the entity's `image_url`. Muscle gallery images are sorted by filename. Missing files
produce `null`/`[]`, so clients never receive a known-broken URL.

The default Compose configuration mounts `/home/agonez/media` instead because that
library already contains exercise images. Set `MEDIA_HOST_PATH=./media` in `.env` to
use this self-contained directory instead.
