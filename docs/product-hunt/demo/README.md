# Product Hunt demo package

Target: **60 seconds**, English narration and captions, public or Unlisted
YouTube full URL.

The script, verbatim English captions, translated Korean captions, shot list,
thumbnail, privacy checklist, and export command are complete. The final
interaction recording is intentionally blocked by the
stable signed and notarized release candidate. Do not upload a fixture animatic
as if it were product evidence.

## Files

- [Storyboard and shot list](storyboard.md)
- [English narration](narration-en.md)
- [English captions](captions-en.srt)
- [Optional Korean captions](captions-ko.srt)
- [Recording checklist](recording-checklist.md)
- [YouTube metadata](youtube.md)
- [Draft thumbnail](../assets/demo/youtube-thumbnail-1280x720.png)

## Final workflow

1. Complete the release and clean-account gates.
2. Record the exact public build using the safe demo project and device.
3. Follow the shot list; condense waiting time only with an on-screen disclosure.
4. Add the final narration and use the English SRT as accessible captions.
5. Export with `Scripts/export-product-hunt-demo.sh raw.mov final.mp4`.
6. Review every frame for private data and unsupported behavior.
7. Upload to YouTube as public or Unlisted and paste the full URL into the live
   Product Hunt form.

Private videos, `youtu.be` short URLs, fake progress, unverified installation,
and claims of remote or permanent signing are not approved.

The exporter writes through a same-volume temporary file with an atomic
no-clobber handoff and verifies 45–75 seconds,
1920×1080 H.264 video, and AAC audio with ffprobe. It refuses to replace an
existing output unless `SIDEREFRESH_OVERWRITE=1` is explicitly set.
