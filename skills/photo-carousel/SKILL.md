---
name: photo-carousel
description: Make an Instagram carousel from the user's photos. Use when the user asks for a carousel, an Instagram post from photos, or to pick the best photos for a post.
---

# Photo carousel

Make a ready-to-post Instagram carousel from photos. Keep text minimal.

## Steps

1. Find the photos. Use the folder the user points to, or `~/photo-content/photos/`.
   Do not scan an entire multi-year library blindly — if the user has not
   given a theme, date range, or album, ask for one first, then look only
   at matching photos.
2. Pick 5 by default (or the number the user asked for):
   sharp, not duplicated, diverse moments and angles, no blurry or dark
   shots unless the user wants them. Order them as a story:
   hook (strongest slide) → context → detail → peak → closer.
3. Copy, never move or edit, the originals in order to
   `output/carousel-<date>-<theme>/01.jpg`, `02.jpg`, and so on.
   Keep the original filenames in a `manifest.txt` in the same folder.
4. Write `caption.txt` in the same folder: a short hook, 2–3 sentences,
   and a call to action. Add hashtags only if the user asks for them.
5. Text on slides is minimal by default. Only add slide text if the user
   asks, and then keep it to a few words per slide in `slides.md`.
6. Show the user the 5 picks and the caption, and confirm before finishing.

## Instagram notes

- All slides must share one ratio; the first slide sets the crop for all.
- Portrait 1080×1350 is the recommended default, up to 20 slides.
- OpenCode cannot post to Instagram for the user. This package is
  ready to upload in order in the Instagram app.

## Language

Answer and write captions in the language the user writes in.
