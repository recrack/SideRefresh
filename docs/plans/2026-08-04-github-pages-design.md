# GitHub Pages publication design

Date: 2026-08-04
Status: approved

## Goal

Publish the existing four-language product site from the canonical public
repository at `https://recrack.github.io/SideRefresh/` without implying that a
signed Mac download or Product Hunt launch is available.

## Decisions

- Remove the unused `recrack.com` custom-domain association from the separate
  `recrack/recrack.github.io` Pages site so project sites use GitHub's HTTPS
  domain again.
- Deploy only a `master` commit, whether triggered by its push or an explicit
  manual run of the reviewed workflow.
- Keep Pages deployment permissions out of the existing CI workflow.
- Pin every GitHub-owned action to a reviewed full commit SHA.
- Build a curated artifact instead of publishing all of `docs/`.

## Artifact contract

The artifact contains only the four route documents, shared CSS, public icon,
synthetic product screenshot, social preview, and `.nojekyll`. Research,
prototypes, launch-source assets, and internal documentation remain available
as repository source but are not directly served by Pages.

A small build script owns this allowlist. A separate validator confirms the
artifact has the exact expected file set, no symbolic links, and a root
`index.html` before upload.

## Workflow contract

The build job checks out the reviewed commit, runs the existing website tests,
builds and validates the curated artifact, configures Pages metadata, and
uploads one `github-pages` artifact. The deploy job alone receives `pages:
write` and `id-token: write`, targets the `github-pages` environment, and
publishes that artifact. Concurrency allows an active production deployment to
finish while replacing a superseded pending run.

## Publication and verification

Publication follows this order so the merge-triggered workflow sees an enabled
Pages site:

1. Delete the root `CNAME` from the legacy publishing source and clear the
   `recrack.com` association from the user-site Pages configuration. Before
   continuing, verify that the source cannot reassert the domain, the Pages API
   reports `cname: null`, and anonymous project URLs no longer redirect to
   `recrack.com`.
2. Enable SideRefresh Pages with `build_type: workflow`.
3. Merge the reviewed pull request and observe the `master` deployment workflow.
4. Verify the Pages API, workflow and deployment status, final HTTPS URL, all
   four language routes, one stylesheet, and one public image.
5. Set the repository homepage to the verified canonical URL and update the
   publication-status documentation.

## Boundaries

This change does not publish a Git tag, GitHub Release, downloadable binary,
Developer ID-signed build, notarization result, or Product Hunt submission.
The website continues to link to source and release status only.

## Rollback

Disable SideRefresh Pages if live verification fails. Restoring a custom domain
requires a separate explicit decision and working DNS; this rollout does not
change DNS records.
