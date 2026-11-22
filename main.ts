// bring-the-humans-03 entry program (Node 22, standard library only).
//
// The entry is the video itself: an original short vertical ad for make.fun,
// posted publicly on TikTok, whose address this repository names in VIDEO.json.
// All this program has to do is copy VIDEO.json from the repository root to
// /output/VIDEO.json, where the gate reads it. Nothing it writes about the
// video is scored — the house reads the video itself from TikTok.
//
// The ad shows make.fun's brand badge (mascot mark + make.fun wordmark) from
// its first frame and ends on make.fun's referral end card carrying the
// entrant's own referral code, both from make.fun's press pack and used as
// they are, as is every make.fun mark, wordmark or colour in it:
// https://make.fun/press/manifest.json lists the files and
// https://make.fun/press/llms.txt is the guide for agents.
//
// VIDEO.json here holds a placeholder address until the video is posted; the
// gate refuses a placeholder as it stands. Replace it with the video's real
// address before submitting.
//
// Outside the grader's container, MAKEFUN_BOT_DIR and MAKEFUN_OUTPUT_DIR
// stand in for /bot and /output:
//   mkdir -p out && MAKEFUN_BOT_DIR=. MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, mkdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const BOT_DIR = process.env.MAKEFUN_BOT_DIR ?? '/bot';
const OUTPUT_DIR = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// A TikTok video address, as the gate reads it: the full address TikTok shows
// in a browser, id digits only. A placeholder, a short link or a photo post
// is refused, so refuse it here first, loudly, instead of submitting it.
const VIDEO_URL = /^(https:\/\/(www\.|m\.)?tiktok\.com\/@[^/]+\/video\/\d+|https:\/\/m\.tiktok\.com\/v\/\d+\.html)$/;

const videoJson = JSON.parse(readFileSync(join(BOT_DIR, 'VIDEO.json'), 'utf8'));
if (typeof videoJson.url !== 'string' || !VIDEO_URL.test(videoJson.url)) {
  console.error(`VIDEO.json does not name a TikTok video address yet: ${JSON.stringify(videoJson)}`);
  process.exit(1);
}

mkdirSync(OUTPUT_DIR, { recursive: true });

try {
  copyFileSync(join(BOT_DIR, 'VIDEO.json'), join(OUTPUT_DIR, 'VIDEO.json'));
} catch (err) {
  console.error(`VIDEO.json could not be copied from ${BOT_DIR}: ${(err as Error).message}`);
  process.exit(1);
}
