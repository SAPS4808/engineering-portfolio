# Shlok Agrawal — Engineering Portfolio

An editorial engineering portfolio hosted entirely on GitHub Pages. No build step, dependencies, API keys, or server are required.

## Live site

https://saps4808.github.io/engineering-portfolio/

## Update without coding

1. Open the live site and click **Edit portfolio** in the footer.
2. Edit your profile, resume sections, and projects. Upload images, captions, and PDFs; reorder projects with the arrow buttons.
3. Click **Save preview** to preview on this device. This does **not** publish to GitHub.
4. Open the editor's **Contact** tab and click **Download content.json**.
5. Click **Upload to GitHub**, drop the downloaded `content.json` into the upload page, and commit it to `main`, replacing the previous file.
6. GitHub Pages publishes the update automatically. Allow a few minutes, then refresh the site.

Anyone can try the local editor, but only repository collaborators can publish changes. Nothing in the editor grants repository access. Local previews stay on your device; published content loads from `content.json`.

Images uploaded in the editor are embedded into the JSON so there are no external image-storage dependencies. Keep images compressed (prefer WebP/JPG); maximum file size is 8 MB. Keep a backup of downloaded content. For large video files, ask for a dedicated hosting integration rather than embedding them.

## Files

- `index.html`: complete responsive site and local editing interface
- `content.json`: published portfolio content
- `shlok-agrawal-resume.pdf`: public resume derived from the supplied resume, without the home street address or personal telephone number
- `favicon.svg`: SA wordmark
- `404.html`: fallback page
- `.nojekyll`: disables Jekyll processing

## Hosting

Settings → Pages → Deploy from a branch → `main` → `/ (root)`.

The previous private site is independent of this GitHub copy. Its edits do not automatically sync here. Update this version through the workflow above, or ask Codex to publish new material to this repository.

## Content notes

Project photographs and robotic-arm demonstrations are supplied by Shlok Agrawal. New project pages contain concise image-led overviews until detailed engineering documentation is provided. The profile and resume list Mechanical Engineering with dual concentrations in Robotics and Technology Innovation.
