# BVT Books — clickable Flutter prototype

Clickable (mock-data, no backend) mobile app for the Bhakti Vikas Trust RFQ v3.0 (books.bvks.com revamp).
Runs on Android, iOS and web (`flutter run -d chrome`). All data is sample data; payments, WhatsApp, Zoho,
couriers and DRM are simulated.

## Run
```
flutter pub get
flutter run            # device/emulator
flutter run -d chrome  # web preview (phone-framed on wide screens)
flutter test
```

## Screens / features covered (RFQ §3.2–3.3, §6.2)
- Onboarding: UI language (EN/HI/GU), preferred book language (16), guest/sign-in, cookie consent
- Home: hero carousel, quick actions, continue reading, subscription CTA, featured, new arrivals,
  language shelves (16), recently viewed, personalised recommendations, testimonials, WhatsApp opt-in
- Search: autocomplete (2 chars, debounced), transliteration (krishna = Krsna = Kṛṣṇa), fuzzy typos,
  Devanagari/Gujarati queries, faceted filters, result count, zero-result state with recommendations
- Listing: grid/list toggle, filters (language, format, category, price, rating, stock, subscription), sort, infinite scroll
- Product page: gallery with zoom, language + format selectors, stock, bulk-price tiers, PIN delivery check,
  sample PDF preview, Subscribe to Read, reviews, customers-also-bought, related, share/deep link, wishlist + back-in-stock alerts
- Subscriptions: per-book / language / global plans, comparison, FAQ, trial, gifting, Razorpay/Stripe/Apple Pay checkout,
  failed-payment + 7-day grace, pause/cancel/upgrade
- In-app reader: chapters, font size, brightness, paper/sepia/night, bookmarks, highlights, progress, offline downloads, DRM notice
- Cart & checkout: qty edit, promo codes (BVT10), shipping estimate, GST split (CGST+SGST/IGST/export), BMM wholesale pricing,
  multi-step checkout, guest checkout + create-account, saved addresses, courier rates, UPI/cards/netbanking/wallets/EMI/COD/Stripe/PayPal/Apple Pay,
  payment failure → retry / partial payment, WhatsApp opt-in, confirmation + invoice
- Orders: history, one-click reorder, tracking timeline with WhatsApp update log, cancel/return, GST invoice
- Account: login/register (email, WhatsApp OTP `123456`, Google, Apple), BMM membership (auto tier), loyalty points, addresses, WhatsApp preferences, notifications
- eBooks (Kindle/Apple Books/Google Play links), Posters (zoom), Donate, Articles (with related books), Bulk order (tiers, CSV, quote)
- AI WhatsApp-style chatbot (English/Hindi, order status, recommendations, FAQ, human hand-off)
- Device features (simulated): biometric login, haptics, offline mode, text scaling, dark mode, home-screen widget preview, Siri Shortcuts, deep-link tester

## Notes
- books.bvks.com (and bvks.com) are blocked by the build environment's network policy, so the catalog could not be scraped. Titles, years, page counts, ISBNs, language availability and a few prices (Brahmacarya ₹95–139, On Pilgrimage ₹220, Bhaktisiddhānta Vaibhava ₹2199) come from real books.bvks.com pages seen via search results. All other prices, stock levels, ratings and reviews are placeholders — re-sync `lib/data/catalog.dart` once the host is allowed.
- GST rates are demo values (books 0%, posters 12%, subscriptions 18%).
- `extras/admin_console_prototype/` holds an unfinished web-only Admin Console prototype (RBAC, CMS, Zoho sync, etc.).
  It is outside `lib/` and not part of the mobile build.
