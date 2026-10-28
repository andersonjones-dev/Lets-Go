# Let's Go

A mobile-first group-trip planner for friends: plan days and drives together, vote on ideas, share tasks and packing, split every expense fairly and settle up by UPI.

## What's in this folder

| File | What it does |
|---|---|
| `index.html` | The whole app: screens, both designs (Classic and Sketchbook) and all logic |
| `config.js` | Your Supabase settings for syncing trips between phones |
| `supabase/setup.sql` | One-time database setup that keeps each trip private to its members |
| `manifest.webmanifest` | Lets the app be added to the Home Screen with its name and icon |
| `sw.js` | Offline support, so the app opens without internet |
| `icons/` | App icons for the Home Screen and browser tab |

## 1. Turn on the website (GitHub Pages)

1. On GitHub, open this repository → **Settings** → **Pages**.
2. Under **Branch**, choose `main` and `/ (root)`, then **Save**.
3. After a minute or two the app is live at `https://andersonjones-dev.github.io/lets-go/`.

Without step 2 below, the app works fully on one phone, but friends can't join your trips.

## 2. Turn on syncing between phones (free Supabase project, about 10 minutes)

1. Go to [supabase.com](https://supabase.com), sign up and create a **New project** (the free plan is fine). Pick the Mumbai region if offered, and save the database password somewhere safe.
2. When the project is ready, open **SQL Editor** → **New query**. Paste everything from `supabase/setup.sql` and tap **Run**. You should see "Success".
3. Open **Authentication** → **Sign In / Providers** (or **Providers**) and switch on **Allow anonymous sign-ins**. This lets friends join with an invite link instead of a password.
4. Open **Project Settings** → **API**. Copy the **Project URL** and the **anon public** key.
5. In this repository, open `config.js`, tap the pencil to edit, paste the two values between the quotes, and **Commit changes**.
6. Open `sw.js`, change `letsgo-v2` to `letsgo-v3`, and commit. (Do this every time you change the app, so phones fetch the new version.)

Open the app, create a trip, then tap **Invite** to send the link on WhatsApp. Friends tap the link, pick their name, and everything stays in sync.

**Free-plan note:** Supabase pauses free projects after about a week with no activity. If sync stops, open your Supabase dashboard and tap **Restore project**.

## 3. Add it to your iPhone Home Screen

Open the app link in Safari → **Share** → **Add to Home Screen**. It opens full screen, like a regular app, and works offline.

## How payments work

- Let's Go never moves money. The **Pay** sheet opens Google Pay, PhonePe, Paytm or any UPI app with the amount and UPI ID filled in, and also shows a UPI QR code.
- Since October 2025, UPI no longer allows "request money" between people, so the person who owes always starts the payment.
- Some UPI apps may decline link-started payments to personal UPI IDs as a security check. If that happens, scan the QR code or copy the UPI ID instead.
- After paying, the payer taps **I've paid**. The person paid checks their bank and taps **Got it**. Balances change only after that.

## Privacy

- Each trip is visible only to phones that opened its invite link. Anyone with the link can join, so share it only with your group.
- Don't store ID numbers, card numbers or passwords in bookings or notes.
- The Supabase keys in `config.js` are designed to be public. The database rules in `setup.sql` protect the data.

## Current limits

- Receipt scanning takes a photo, but you type the details. Automatic reading isn't connected.
- No push notifications yet. Changes show up when the app is open.
- If someone clears their browser data, they rejoin with the trip's invite link.
