# 10 — App Store Listing Reference

Values App Store Connect asks for that live nowhere else in the repo. Update this file when any of them change.

## Privacy policy

- **URL (paste into App Store Connect → App Privacy → Privacy Policy URL):**
  <https://pdfhost.io/v/Quvw53LjUd_iBase-Privacy-Policy>
- **Source document:** `iBase-Privacy-Policy.pdf` in the repo root — the hosted copy must be re-uploaded whenever this file is regenerated, and the URL re-checked.
- **App Privacy questionnaire:** answer **Data Not Collected** for every category. The policy and the questionnaire must agree; a mismatch is a common review rejection.
- **Re-publish trigger:** shipping optional iCloud sync. The policy already describes sync as a future, optional feature, but it needs a new effective date and a fresh upload before that version is submitted.

## Version 2.0.0 copy

**Promotional text** (170 char limit, editable without a new build — currently 164):

> The number is a readout, not a text field. See any value live in every base 2–36 plus Base64 — bit field, radix-aware keypad, history. Now on iPhone, iPad, and Mac.

**What's New:**

> **iBase 2.0 is a complete redesign.** The number is a readout, not a text field.
>
> • All-new instrument-panel look — dark, focused, one green accent
> • Every base 2–36 plus Base64, live at once. Nothing to submit — it's already converted
> • New radix-aware keypad: digits illegal in your base dim instead of hiding, so you learn each base's alphabet as you type
> • Bit field readout — see exactly which bits are set, MSB to LSB
> • History — every value you enter is saved; tap to bring it back
> • Now on iPad and Mac, one adaptive layout
> • Haptic, spring-loaded interactions throughout. Fully usable silently
>
> Questions or ideas? We'd love to hear them.

## Version 2.0.0 copy — Spanish (es-MX / es-ES)

Neutral Latin American Spanish; works for both storefronts.

**The app itself ships this language too** — one `es` localization in
`iBase/Localizable.xcstrings`, `InfoPlist.xcstrings`, and `AppShortcuts.xcstrings`, using the same
terminology as the copy below (historial, campo de bits, confirmar, base). So the listing must
declare Spanish as an app language in App Store Connect, not only as a localized listing.
`BIN`/`OCT`/`DEC`/`HEX`/`B64` and every converted digit stay untranslated in the UI, by decision —
they are notation.

To run the app in Spanish for a layout-fit pass, add `-AppleLanguages (es)` to the scheme's
Arguments Passed On Launch (Product → Scheme → Edit Scheme → Run → Arguments).

**Texto promocional** (168 of 170 characters — recount before editing):

> El número es una lectura, no un campo de texto. Todo valor en vivo en las bases 2–36 y Base64: campo de bits, teclado por base e historial. Ahora en iPhone, iPad y Mac.

**Novedades:**

> **iBase 2.0 es un rediseño completo.** El número es una lectura, no un campo de texto.
>
> • Nuevo aspecto de panel de instrumentos: oscuro, enfocado, un solo acento verde
> • Todas las bases 2–36 y Base64 a la vez. Nada que enviar: la conversión ya está hecha
> • Nuevo teclado que conoce la base: los dígitos que no existen en esa base se atenúan en lugar de desaparecer, así aprendes el alfabeto de cada base mientras escribes
> • Campo de bits: mira exactamente qué bits están encendidos, del más significativo al menos significativo
> • Historial: cada valor que ingresas queda guardado; tócalo para recuperarlo
> • Ahora en iPad y Mac, con un solo diseño adaptable
> • Interacciones hápticas y con animaciones de resorte. Totalmente usable en silencio
>
> ¿Preguntas o ideas? Nos encantaría escucharlas.

## Notes for Reviewer

Paste into App Store Connect → App Review Information → Notes. No demo account is needed (the Sign-in required toggle stays off).

> No sign-in, no account, and no network connection are required — iBase works fully offline and all conversion happens on device.
>
> How to exercise the app in about a minute:
>
> 1. The main screen is a live readout. The value at the top is shown simultaneously in every base from 2 to 36 plus Base64 in the list below; nothing needs to be submitted.
> 2. Tap the value to open the keypad. Digits that are not valid in the current base appear dimmed and are intentionally non-responsive — for example, in base 10 the letter keys A–F are dimmed; switch the base to 16 and they become active. This is the app's core teaching idea, not a bug.
> 3. Enter a value (e.g. 7E in base 16) and confirm. The readout updates and the entry is added to History.
> 4. Open History from the toolbar to see saved values; tap one to load it back into the readout, or swipe to delete. History is stored only on the device and can be cleared from the menu.
> 5. Settings lets you hide or show individual bases in the readout list.
>
> The app is intentionally dark-only; that is a design decision, not a missing light appearance. It collects no data of any kind, uses no third-party SDKs, and makes no network requests, which is why the App Privacy responses are "Data Not Collected." Privacy policy: https://pdfhost.io/v/Quvw53LjUd_iBase-Privacy-Policy
>
> Contact for any questions during review: Juan Carlos Estevez, juancarlos_tec@proton.me

## Identifiers

- Bundle ID: `com.JCTechnologies.iBase` (tests: `.tests`, `.uitests`)
- Team ID: `S8662L649U` (set in `project.yml`, not in Xcode's UI — see `README.md`)
- Marketing version 2.0.0 / build number: `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION` in `project.yml`
- Support contact: Juan Carlos Estevez — juancarlos_tec@proton.me

## Screenshots

Generated, never hand-made: `bundle exec fastlane ios screenshots` → `AppStoreAssets/iPhone-6.9/` and `AppStoreAssets/iPad-13/` (see `08-Tooling.md`).
