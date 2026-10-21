# Shlok Agrawal — Engineering Portfolio

An editorial engineering portfolio hosted entirely on GitHub Pages. No build step, dependencies, API keys, or server are required.

## Live site

https://saps4808.github.io/engineering-portfolio/

## Updates

The public site is read-only and contains no portfolio editor. Send content or image updates through the existing Codex chat to update this repository. GitHub Pages publishes commits to `main` automatically.

Project videos have their audio tracks removed and preserve their natural portrait or landscape orientation. The showcase uses actual moving videos rather than extracted posters.

## Files

- `index.html`: complete responsive site 
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


## CAD viewer
The ME360 project uses locally hosted Three.js (MIT; see THREE-LICENSE.txt) and STL exports. Project model lists and internship cards are editable in content.json. The CAD viewer includes a complete presentation assembly reconstructed from the supplied component meshes and video, plus each source STL. Reconstructed reference geometry can be hidden. See me360-assembly-notes.txt for provenance and approximation limits.
