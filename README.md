# Let's Go

A mobile-first group-trip planner: vote on ideas, build the itinerary, share tasks, split expenses each in their own way, and settle up over UPI.

## What's in this folder

| File | What it does |
|---|---|
| `index.html` | The whole app (screens, styling and logic) |
| `manifest.webmanifest` | Lets the app be added to the Home Screen with its name and icon |
| `sw.js` | Offline support, so the app opens without internet |
| `icons/` | App icons for the Home Screen and browser tab |

No accounts, API keys or paid services are needed.

## Current limits

- Data is saved on each phone only (browser storage). Friends don't see each other's changes yet.
- Receipt scanning takes a photo, but details are typed by hand. Automatic reading isn't connected.
- Payments happen in your own UPI app. "Mark as paid" only records them.
- WhatsApp sharing is always started by you. The app can't read WhatsApp groups.

## Updating the app later

When you upload a new `index.html`, also open `sw.js` and change `letsgo-v1` to `letsgo-v2` (then v3, and so on). That tells phones to fetch the new version.

## Suggested next step

Shared trips across phones need a small online database. A free Supabase project is the smallest practical option.
