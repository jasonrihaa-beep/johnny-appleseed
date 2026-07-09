# PHOTO SPEC — Plant Photos + Sign-in Caption (v0.15.0)

Execution contract. Sonnet default. All decisions final.
User photo upload with compression, honest illustration
fallback, storage-backed, never blocking a log. Plus the
deferred sign-in caption.

## Design decisions (fold into CLAUDE_CONTEXT.md on ship)

1. Client-side compression is mandatory: canvas downscale to
   max 1280px longest edge, JPEG quality 0.82, before upload.
   Free-tier storage math depends on it.
2. Upload path: plant-photos/{auth.uid()}/{crypto.randomUUID()}.jpg
   — filename independent of plant id, upload BEFORE insert,
   photo_url included in the single insert. If insert fails
   after upload, best-effort storage remove in the catch.
3. Photos never block a log: any upload failure → toast +
   proceed offering log-without-photo. Same philosophy as the
   GPS fallback.
4. Fallback is a SINGLE universal botanical line-art SVG
   placeholder — visibly an illustration (stroke 1.6, stone-500
   on green-50), depicting a generic sprig, alt text
   "Illustration — no photo yet". Must NOT appear to depict the
   specific species (honest-states). Per-plant sketch library
   is a separate asset-lane project; render order once it
   exists: user photo → per-plant sketch → placeholder.
5. photo_url is rendered escaped; images load lazy
   (loading="lazy"), object-fit cover, fixed aspect container
   (no layout shift).
6. Own-plant delete does best-effort storage remove of its
   photo (orphaned files otherwise accepted, documented).
7. Sign-in caption (deferred from onboarding): a small caption
   under the setup sheet's Google button, exact text "Your
   garden stays yours on any device. Without it, your plants
   live only in this browser." Both clauses are literally true
   (anonymous accounts die with site data). Muted styling,
   no emoji.

## Claude Code tasks (one commit, v0.15.0)

### Task 1 — Photo picker on Plant form
New form group "Photo (optional)" below Note: styled tap target
wrapping <input type="file" accept="image/*"> (gallery OR
camera via OS chooser). On select: show preview thumbnail
(object-fit cover, 4:3, rounded 10px) + a remove control
(stroke SVG X). No upload occurs at selection time. This group
sits ABOVE the sticky submit bar (inside #plant-view flow).

### Task 2 — Compress + upload in submitPlant
Before the insert, if a photo is selected: ensureAuth() →
canvas-resize to max 1280px longest edge, toBlob('image/jpeg',
0.82) → sb.storage.from('plant-photos').upload(
'{uid}/{randomUUID}.jpg', blob, { contentType: 'image/jpeg' })
→ getPublicUrl → include photo_url in the existing single
insert. Upload error → toast the message + confirm-continue
without photo (never block). Insert error after successful
upload → best-effort .remove([path]) in the catch, then
existing error handling.

### Task 3 — Rendering
- Feed cards: when photo_url present, image above the note,
  full card width, 4:3 cover, rounded, lazy. When absent, the
  universal placeholder SVG in the same container at reduced
  visual weight (background green-50).
- Map DB-pin popups: when photo_url present, thumbnail strip
  (fixed height ~110px, cover, rounded) above the byline —
  fixed dimensions so Leaflet popup needs no reflow handling.
  No placeholder in popups (space-constrained; omit instead).
- All photo_url values escaped before hitting HTML.

### Task 4 — Delete hygiene
In the existing own-plant delete path: after successful row
delete, if the plant had a photo_url in this bucket, parse the
storage path from it and call .remove([path]) best-effort
(errors logged to console only, no user-facing failure).

### Task 5 — Sign-in caption
Add the decision-7 caption line directly under the "Continue
with Google" button in the setup sheet (both contexts — it is
one sheet component). Muted text token, small size, no emoji.

### Task 6 — Version, docs
Fan-out: footer v0.15.0 + sw.js CACHE appleseed-v0-15-0.
CLAUDE_CONTEXT.md: decisions above, landmarks (picker,
compress/upload fn, placeholder SVG, delete hygiene, caption),
roadmap (S2.5 shipped; per-plant sketch library pending asset
lane).

### Task 7 — Post-deploy self-verify (rule 11, four probes)
1. index.html: v0.15.0 + markers (photo input id, compress fn,
   getPublicUrl usage, placeholder SVG id, caption text)
2. sw.js cache = appleseed-v0-15-0
3. GET {SUPABASE_URL}/storage/v1/object/public/plant-photos/probe-nonexistent.jpg
   → any 400/404 object-not-found response = PASS (bucket
   exists and is public); a "Bucket not found" body = FAIL,
   report that Box 5 SQL is still pending
4. GET {SUPABASE_URL}/rest/v1/plants?select=lat,lng&limit=5
   with apikey + Bearer → 200, all ≤ 3 decimals
No data mutation. Report table, stop.

## Acceptance (Jason)
- Log a plant WITH a photo from the Pixel camera → success →
  photo on the feed card and in its map popup → Supabase
  Storage shows one file well under 300KB
- Log a plant WITHOUT a photo → placeholder illustration
  renders, clearly not a species photo
- Airplane-mode the upload (or deny mid-flow) → toast → log
  still completes without photo
- Delete a photo plant → row gone AND its storage file gone
- Setup sheet shows the caption under Continue with Google
