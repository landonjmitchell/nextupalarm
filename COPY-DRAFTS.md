# Copy drafts — edit freely, these are starting points

## Promotional Text (App Store Connect → version page)

The only store copy editable **without shipping a build**. 170 char limit. Appears above the description.

**Option A — plain, recommended**
> Known issue: on recent iOS versions alarms may not fire reliably. A full rebuild is underway. Help and status: nextupalarm.com
*(126 chars)*

**Option B — warmer**
> Thanks for your patience — this version has reliability problems on newer iOS. A rebuilt version is in progress. Details at nextupalarm.com
*(138 chars)*

**Option C — minimal**
> Support and current status: nextupalarm.com
*(43 chars)*

A is the honest disclosure at the point of download. C if you'd rather not foreground the problem.

---

## Review replies

Public, immediate, editable later, and they notify the reviewer. Prioritize 2024–2026 reviews.

**For "the alarm doesn't fire" (the most common)**
> You're right, and I'm sorry — this is a real defect, not something you did wrong. The app keeps itself running in the background to play your podcast, and newer versions of iOS shut that down aggressively. I'm rebuilding it on Apple's new alarm APIs (iOS 26), which let the system fire the alarm directly and fix the underlying cause. Support and status: nextupalarm.com

**For battery drain**
> That drain is real and it comes from the same design problem — keeping the app alive all night to play audio is expensive. The rebuild moves alarm handling to the system, which removes the need. Sorry it cost you battery in the meantime.

**For "podcasts don't show up / plays the wrong thing"**
> This one's Apple-side: the app reads episodes that Podcasts has downloaded to your device, and Apple Podcasts has moved toward streaming with automatic cleanup, so there's often nothing local to find. The rebuild includes its own podcast downloading so it no longer depends on that. Details: nextupalarm.com/faq

**For support that went unanswered**
> You wrote and got nothing back — that's on me. The support address broke when the site's hosting lapsed and I didn't notice for too long. It works again now: support@nextupalarm.com. If your issue is still live, please write and I'll answer.

---

## Support email auto-reply (optional, once Cloudflare routing is live)

> Thanks for writing about Next Up.
>
> If you're here because an alarm didn't fire, or a podcast didn't play: those are known problems with the current version, and nextupalarm.com/faq explains what helps and what can't be worked around. A full rebuild is underway.
>
> I read everything sent here. If you included your iPhone model and iOS version, that helps a lot.
>
> — Landon
