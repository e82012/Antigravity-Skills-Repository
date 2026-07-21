# HIG Cheatsheet

Condensed cheatsheet distilling 55 HIG topics. Rules are platform-agnostic (mobile = iOS/Flutter/RN; desktop = macOS/Tauri/Electron). Cite the topic name in reviews.

**Topic index (Ctrl-F):**
Foundations — color, typography, layout, materials, dark-mode, icons, sf-symbols, app-icons, branding, images, motion, liquid-glass
Accessibility & Inclusion — accessibility, inclusion, right-to-left, privacy
Interaction — gestures, keyboards, pointing-devices, apple-pencil-and-scribble, focus-and-selection, game-controls, drag-and-drop
UX Patterns — onboarding, launching, loading, modality, feedback, entering-data, searching, settings, managing-accounts, managing-notifications, offering-help, file-management, undo-and-redo, multitasking, going-full-screen, collaboration-and-sharing, ratings-and-reviews, writing, charting-data, printing
Media — playing-audio, playing-video, playing-haptics, live-viewing-apps
Technologies — apple-pay, in-app-purchase, maps, machine-learning, generative-ai, augmented-reality

---

## Foundations

### color
- Use color consistently; never use one color to mean different things (e.g. don't reuse an interactive brand color on noninteractive text).
- Never rely on color alone for status, interactivity, or essential info — pair with text labels or shapes.
- Risky color-blind pairs: red-green, blue-orange.
- Prefer semantic/dynamic system colors that adapt automatically to appearance + accessibility.
- Supply light, dark, and increased-contrast variants for every custom color.
- Don't hard-code system color values (they shift between releases).
- Don't redefine a semantic color's meaning (e.g. separator color used as text).
- Use sRGB for accurate color on most displays.
- Use Display P3 (16 bits/channel, export PNG) for wide-color displays.
- Test the color scheme on multiple devices and lighting conditions.
- Consider cultural color meanings (e.g. red = danger vs. luck).
- Mobile background sets: system + grouped, each with primary (overall view) / secondary / tertiary (nested) hierarchy.
- Mobile foreground colors: label, secondary/tertiary/quaternary label, placeholder, separator, link.

### typography
- Default / minimum text sizes: mobile **17pt / 11pt**; desktop **13pt / 10pt**.
- Custom fonts follow the same minimums; go larger than recommended for thin weights.
- Prefer Regular, Medium, Semibold, Bold.
- Avoid Ultralight, Thin, Light (hard to read at small sizes).
- Minimize the number of typefaces (too many obscure hierarchy).
- Use built-in text styles to express hierarchy and get scalable-text support automatically.
- Support scalable/dynamic text: layout must stay legible at all sizes.
- Keep truncation minimal as font size grows; show as much useful text at the largest accessibility size as at the largest standard size.
- Prioritize important content when scaling — don't scale everything (e.g. tab titles).
- Keep information hierarchy consistent at very large sizes; consider stacked layouts when horizontally constrained.
- Custom fonts must be legible and implement scalable-text + Bold Text behaviors.
- Mobile supports scalable text; desktop does not. Serif (New York) is available on both.

### layout
- Group related items using spacing, background shapes, colors, materials, or separators; keep controls distinct from content.
- Give essential info sufficient space; don't crowd it with secondary detail.
- Extend content/backgrounds to the screen edges; scrollable layouts run all the way to the edges.
- Controls (sidebars, tab bars) float above content, not on the same plane.
- Respect safe areas and margins; avoid Dynamic Island, camera housing, and the status-bar area.
- Place important items top + leading (reading order); vary by language for RTL.
- Align components to aid scanning; use progressive disclosure for hidden content.
- Adapt to device size, orientation, size classes (regular/compact), external displays, resizable windows, text-size changes, and RTL.
- Design the full-screen layout first; defer switching to a compact view as long as possible.
- Test at system window sizes (halves, thirds, quadrants) and provide smooth transitions.
- Mobile: support both portrait + landscape; if landscape-only, work in both rotation directions.
- Mobile: avoid full-width buttons (respect side margins); if needed, harmonize with hardware curvature.
- Mobile: hide the status bar only for immersive media/games.
- Desktop: avoid controls or critical info at the window bottom (often moved offscreen).
- Desktop: avoid content within the top camera housing.
- Scale artwork for different displays — don't change its aspect ratio.

### materials
- A material creates depth/hierarchy by separating foreground (text, controls) from background (content), letting color pass through.
- Choose transparency to balance visual appeal with readability.
- Test materials across different background content and lighting.
- See `liquid-glass` for the functional/content layering system and thickness levels.

### dark-mode
- Respect the systemwide setting; do NOT offer an app-specific appearance toggle.
- Support light, dark, and Auto (which switches during use).
- Dark Mode is not a pure inversion — some colors invert, some don't.
- Use semantic colors; supply bright + dim variants for custom colors via an asset catalog.
- Contrast minimum **4.5:1** foreground/background.
- Strive for **7:1** with custom colors, especially small text.
- Test with Increase Contrast + Reduce Transparency (separately and together) — dark text on dark can become illegible.
- Slightly darken white-background images to prevent glow in dark context.
- Mobile uses two dark background sets: **base** (dimmer, recedes) and **elevated** (brighter, advances) for foreground surfaces like popovers/modals. Prefer system backgrounds.
- Use system label colors (primary/secondary/tertiary/quaternary) and system views for text.

### icons
- One concept, highly simplified, familiar metaphor.
- Keep consistent size, detail, stroke weight, and perspective across all icons.
- Match icon weight to adjacent text unless deliberately emphasizing one.
- Optically (not just geometrically) center asymmetric icons via padding.
- Custom interface icons: use vector (PDF/SVG) so the system scales them; PNG needs multiple resolutions.
- Provide alternative-text labels for custom icons.
- Don't provide selected-state variants for standard components — the system tints selected icons with the accent color automatically.
- Use inclusive, gender-neutral figures.
- Localize/flip any embedded text; avoid replicas of hardware products.
- Desktop document icons use a folded-corner paper look; can display as small as **16x16px**.
- Keep the document-icon image within ~**80%** of the canvas (~**10%** margin); avoid content in the top-right corner (masked by the fold); reduce complexity at small sizes.

### sf-symbols
- Framework-agnostic icon system: consistent, weight-matched symbols that align with the system font.
- Available in 9 weights (ultralight→black) matching font weights, and 3 scales (small, medium default, large).
- Four rendering modes: monochrome, hierarchical (one color, layered opacities = depth), palette (one color per layer), multicolor (intrinsic meaningful colors).
- Use system colors so symbols adapt to Dark Mode, vibrancy, and accessibility.
- Variable color communicates a changing quantity (0–100% across layers) — use for change, NOT depth (use hierarchical for depth).
- Variants: outline (default, alongside text), fill (emphasis/selection, tab bars, swipe actions), slash (unavailable), enclosed (legibility at small sizes).
- Many language/script-specific and RTL variants adapt automatically when the device language changes.
- Apply animations judiciously (appear, bounce, pulse, replace, wiggle, rotate, etc.) — each must serve a clear communicative purpose.
- Custom symbols: match the template's detail/weight/alignment/perspective; annotate layers; provide alt-text; don't replicate products.

### app-icons
- Use layers (background + foreground) for depth; let the system apply highlights/shadows/blur/masking.
- Don't bake in specular highlights, drop shadows, bevels, glows, or blurs.
- Prefer clearly-defined edges (no soft/feathered edges) in foreground layers.
- Vary foreground-layer opacity for depth.
- Prefer vector (SVG/PDF); use PNG for mesh gradients / raster artwork.
- Canvas **1024x1024px**; color spaces sRGB + Gray Gamma 2.2.
- Mobile icons are square (system rounds corners); keep primary content centered to survive masking.
- Embrace simplicity — minimal shapes, simple background.
- Include text only when essential (text doesn't localize or support accessibility).
- Prefer illustration over photos; don't replicate UI components or hardware products.
- Support default, dark, clear, and tinted appearances; keep core features consistent across all.
- Base the dark icon on the light one, using complementary, non-bright colors.

### branding
- Express brand while deferring to content; don't waste screen space on pure brand assets.
- Incorporate branding unobtrusively; don't repeat the logo throughout the app.
- Consider an accent color the system applies to icons, buttons, and text.
- Consider a custom font for headlines, but use the system font for body/captions (legibility at small sizes).
- Ensure custom fonts support Bold Text + larger type.
- Use standard patterns, locations, and symbols so even stylized UIs stay approachable.
- Don't use the launch screen as a branding opportunity — use a welcome/onboarding screen instead.
- Trademarks must not appear in the app name or images.

### images
- A point maps to pixels by scale factor: @1x (1:1), @2x (2:1), @3x (3:1).
- Provide assets at: mobile **@2x + @3x**; desktop **@1x + @2x**.
- Design at the lowest resolution and scale up; align vector control points to whole values for clean rasterization.
- Formats: de-interlaced PNG for bitmap; 8-bit palette PNG when <24-bit color suffices; JPEG for photos; PDF/SVG for flat/scalable artwork.
- Embed a color profile in each image.
- Test images on a range of real devices.

### motion
- Add motion purposefully; gratuitous/excessive animation distracts and can cause discomfort.
- Make motion optional; supplement with haptics/audio — never the sole channel for important info.
- Feedback motion should be realistic and follow the user's gesture (dismiss should mirror reveal direction).
- Keep feedback animations brief and precise.
- Avoid adding motion to frequent UI interactions (the system already animates standard elements).
- Let people cancel/skip animations rather than waiting for them.
- Games: maintain **30–60 fps** for smooth motion.
- Let people trade visual fidelity for performance/battery.

### liquid-glass
- A translucent **functional layer** (tab bars, toolbars, sidebars, floating CTAs, system overlays) floats above the **content layer** (text, images, lists, media).
- Establishes a clear two-layer hierarchy; content scrolls and shows through beneath.
- Has no inherent color — it takes color from the content directly behind it.
- Small elements (toolbars, tab bars) adapt light/dark to underlying content; large elements (sidebars) stay more opaque for legibility.
- Scroll edges blur and reduce content opacity to keep controls legible.
- **Regular** variant: blurs + adjusts luminosity for legibility; use for text-heavy components (alerts, sidebars, popovers) — most system components.
- **Clear** variant: highly translucent, for components over media; more immersive.
- Clear over bright content → add a dark dimming layer (~**35% opacity**); over sufficiently dark content → no dimming needed.
- Do NOT use in the content layer (cards, list items, backgrounds) or decoratively.
- Use sparingly, limited to the most important functional elements; overuse dilutes emphasis.
- Exception: transient content-layer controls (sliders, toggles) may adopt the look when activated.
- Color on glass: symbols/text go monochromatic — darker over light content, lighter over dark content.
- Emphasize a primary action by coloring the **background** (e.g. "Done"), not the foreground.
- Color selected nav items on the **foreground**.
- Only one background-colored primary action per context.
- Keep toolbars/tab bars monochromatic in colorful apps; avoid content/control color overlap.
- Standard (non-glass) material thickness: **ultra-thin** (most translucent) → **thin** → **regular** (default) → **thick** (most opaque).
- Choose material by semantic meaning, not apparent color.
- Vibrancy for labels: primary (default) → secondary → tertiary → quaternary (avoid quaternary on thin/ultra-thin).
- Vibrancy for fills: primary → secondary → tertiary.
- **Flutter:** `BackdropFilter` + `ImageFilter.blur()`, semi-transparent `Container`, `ClipRRect` for rounded corners; adapt opacity/blur to underlying brightness.
- **Tauri/Electron:** CSS `backdrop-filter: blur()` + `background: rgba()` + `-webkit-backdrop-filter`; `mix-blend-mode` for vibrancy; `prefers-color-scheme` for adaptation.
- **React Native:** `BlurView` (@react-native-community/blur) + semi-transparent overlays; adjust blur/tint by context.
- Key values: blur radius **20–40px** regular, **10–20px** clear.
- Key values: background opacity **0.6–0.8** regular, **0.3–0.5** clear.
- Key values: saturation boost **1.2–1.5x**; adaptive tint by underlying brightness; increase blur / reduce opacity at scroll edges.

---

## Accessibility & Inclusion

### accessibility
- An accessible interface is intuitive, perceivable (not reliant on a single sense), and adaptable.
- Vision: allow enlarging text by ≥**200%**.
- Custom type sizes follow platform defaults (mobile 17/11pt, desktop 13/10pt); go larger for thin weights.
- Contrast (WCAG): up to 17pt any weight → **4.5:1**.
- Contrast: 18pt any weight → **3:1**.
- Contrast: any size Bold → **3:1**.
- Provide a higher-contrast scheme when Increase Contrast is on; check both light + dark.
- Convey info with more than color (shapes, icons); allow customizing chart/character colors.
- Support screen readers with described interface + content.
- Hearing: provide captions, subtitles, audio descriptions, and transcripts.
- Pair audio cues with matching haptics + visual cues (important off-screen for games/spatial apps).
- Mobility — control size: mobile default **44x44pt**, min **28x28pt**; desktop default **28x28pt**, min **20x20pt**.
- Spacing: ~**12pt** padding around bezeled elements; ~**24pt** around non-bezeled visible edges.
- Use the simplest possible gesture for frequent actions; avoid custom multifinger/multihand gestures.
- Always offer a non-gesture alternative (e.g. a button beside swipe-to-delete).
- Support Voice Control, Switch Control, Full Keyboard Access, pointer control; label elements properly.
- Cognitive: keep actions simple and consistent; prefer familiar system gestures.
- Minimize time-boxed/auto-dismissing elements; prefer explicit dismissal.
- Don't autoplay audio/video without controls; let people opt out globally.
- Respect Dim Flashing Lights during video playback.
- Respect Reduce Motion: tighten springs, track gestures directly, avoid z-axis depth animation, replace x/y/z transitions with fades, avoid animating blurs.
- In simplified-access modes: remove noncritical UI, one interaction per screen, confirm irreversible actions twice.

### inclusion
- Design for a spectrum of perspectives (age, gender identity, race, ability, language, culture, religion, economics).
- Use empathy; examine assumptions; treat it as iterative.
- Use plain, welcoming language; address people as "you/your".
- Reserve "we/our" for your company/software; avoid ambiguous "we" (especially in errors).
- Define technical terms before using them.
- Avoid colloquialisms and humor (hard to translate; can exclude or offend).
- Avoid unnecessary gender references; prefer gender-neutral nouns and drop singular gendered pronouns.
- Use nongendered human images for generic people.
- Offer inclusive gender options (nonbinary, self-identify, decline) only when the info is genuinely needed.
- Portray diverse people and relatable settings; avoid stereotypes and narrow "family"/affluence assumptions.
- Avoid context-specific security questions that exclude people.
- Internationalize early (dates, currency, layout direction, text length).
- Check color meanings across locales (e.g. white = grief vs. purity).
- Use people-first language for disability; support all system accessibility features.

### right-to-left
- System frameworks flip standard UI automatically; fine-tune only custom layouts.
- Align 1–2 line text to the current context's direction; align paragraphs (3+ lines) to their own language.
- Use consistent alignment for all items in a list, even mixed-script items.
- Never reverse digit order within a specific number (phone, credit card, "541").
- Reverse the ORDER of numerals that show progress/sequence — never flip the numerals themselves.
- Flip controls showing progress or fixed-order navigation (sliders, progress bars, back/next).
- Preserve controls that reference a real direction or point to an onscreen area.
- Increase RTL (Arabic/Hebrew) font size by ~**2 points** to balance against all-caps Latin text.
- Don't flip photos/artwork (changes meaning; possible copyright issue) — recreate if reading-direction-dependent.
- Reverse positions of ordered image sets to preserve meaning.
- Flip icons representing text or forward/backward motion.
- Never flip logos, universal marks (checkmark), clocks, or real-world objects.

### privacy
- Request access only to data you actually need, and only when the feature needs it.
- Don't request at launch unless the data is essential to function.
- Purpose strings: brief, complete, active-voice sentence; sentence case; ending period.
- Good purpose string is specific ("The app records during the night to detect snoring sounds") — not vague/passive/imperative.
- Optional pre-alert screen: one button titled "Continue"/"Next" (never "Allow").
- Pre-alert screen: no cancel/close/other actions; never mimic, image, or annotate the system alert; never offer incentives (causes rejection).
- Process data on-device where possible.
- Use system encryption/keychain; never store passwords/secrets in plain text.
- Prefer passkeys over passwords; add two-factor + biometric (Face ID/Touch ID) for kept-logged-in sessions.
- Avoid custom authentication schemes.
- Mobile location button grants one-time access matching the current task.
- Location button customizable only in title, glyph (filled/outline), colors, corner radius — nothing else; must stay legible.
- Desktop: sign with Developer ID; use app sandboxing; account for fast user switching (don't assume who's signed in).

---

## Interaction

### gestures
- Give more than one way to do anything; don't assume a specific gesture is available.
- Respond consistently with expectations (tap = activate/select).
- Don't repurpose familiar gestures for app-unique actions, or invent gestures for standard actions.
- Handle gestures responsively with immediate feedback.
- Indicate when a gesture is unavailable so the app doesn't seem frozen.
- Add custom gestures only for specialized frequent tasks; must be discoverable, easy, distinct, and never the only way.
- Don't conflict with system gestures.
- Standard (all platforms): tap, swipe, drag, touch/pinch-and-hold, double tap, zoom, rotate.
- Mobile extras: three-finger swipe (undo/redo), three-finger pinch (copy/paste), four-finger swipe (switch apps), shake (undo/redo).

### keyboards
- A shortcut = primary key + modifiers (Control, Option, Shift, Command); a game key binding is often a single key.
- Respect standard shortcuts; only redefine one if its action is irrelevant to your app.
- Support Full Keyboard Access on mobile + desktop.
- On mobile, don't add keyboard navigation for controls (buttons, switches) — let Full Keyboard Access handle them.
- Define custom shortcuts only for the most frequent app-specific commands.
- Prefer Command as the main modifier; Shift as a complementary secondary; Option sparingly; avoid Control (system-reserved).
- List modifiers in order: Control, Option, Shift, Command.
- Don't add Shift for a two-character key's upper character.
- Don't build a new shortcut by adding a modifier to an unrelated command's shortcut.
- Common standards: ⌘Z undo, ⇧⌘Z redo, ⌘C/⌘X/⌘V copy/cut/paste, ⌘A select all, ⌘F find.
- Common standards: ⌘S save, ⌘P print, ⌘N new, ⌘O open, ⌘W close, ⌘Q quit, ⌘, settings.
- Common standards: ⌘B/⌘I/⌘U bold/italic/underline, ⌃⌘F full screen, ⌘H hide app.

### pointing-devices
- Respond consistently to mouse/trackpad gestures; don't redefine systemwide gestures.
- Provide a consistent experience across touch, pointer, keyboard, and eyes.
- Match modifier+drag behavior between touch and pointer (e.g. Option = duplicate).
- Let the pointer reveal/hide auto-minimizing controls (e.g. video playback controls).
- Mobile pointer adapts shape by context (circle default, I-beam over text).
- Highlight effect: small transparent-background elements (bar buttons, segmented controls).
- Lift effect: small opaque elements (app icons).
- Hover effect: large elements with custom scale/tint/shadow.
- Magnetism applies to highlight + lift + text areas, not hover.
- Add hit-region padding: ~**12pt** around bezeled elements, ~**24pt** around non-bezeled edges.
- Make custom bar-button hit regions contiguous.
- Keep custom pointer shapes simple; avoid gratuitous/decorative effects; avoid instructional text on the pointer.
- Desktop pointers signal state: arrow, I-beam, open/closed hand, crosshair, pointing hand, resize, copy, drag-link, disappearing-item, operation-not-allowed, contextual-menu.

### apple-pencil-and-scribble
- (Stylus, tablet only.) Support real-world marking expectations (e.g. writing in margins).
- Let people switch freely between stylus and finger — controls must respond to the stylus too.
- Mark the instant the stylus touches — no mode/button first.
- Give direct, immediate visual feedback tied to what it touches.
- Respond to tilt (altitude), force (pressure), orientation (azimuth), and barrel roll; map pressure to continuous properties (opacity, brush size).
- Design for both left- and right-handed use (don't obscure controls).
- Hover: preview the mark the tool will make; don't vary preview by height; show a mid-range preview value.
- Don't use hover to initiate actions (especially destructive).
- Double tap / squeeze: respect user settings; use only for nondestructive, easy-to-undo actions.
- Squeeze = single discrete action shown near the tip; not continuous.
- Barrel roll: only to modify marking, not navigation.
- Scribble: works in all standard text fields (except password) with no mode switch.
- While writing: don't show autocompletion/placeholder over the writing; keep the field stationary and non-autoscrolling; give enough room to write.

### focus-and-selection
- Focus visually confirms the interaction target (ring or highlight).
- Rely on system-provided focus effects; create custom ones only if absolutely necessary.
- Don't change focus without user interaction.
- Exception: when a focused item disappears during directional navigation, move focus to a nearby item; otherwise hide the indicator.
- Only support focus for content elements (list items, text/search fields, collections) — Full Keyboard Access handles controls.
- Use a focus **ring** for text/search fields; a **highlight** for lists/collections.
- Focus moves in reading order (leading→trailing, top→bottom).
- Group custom views into focus groups; raise priority of a group's primary item.

### game-controls
- Support the platform's default input (touch / keyboard+mouse) as a fallback even if you support controllers.
- Touch controls: minimum **44x44pt** for frequent controls, **28x28pt** for less-important ones.
- Place touch controls near thumbs, clear of the Home indicator/Dynamic Island; movement on left, camera on right.
- Always show visible + tactile press states (plus sound/haptics).
- Use action-representing symbols (not "A"/"X"/"R1").
- Show/hide touch controls by context; use a dynamic thumbstick where the thumb lands.
- Physical controllers: auto-detect pairing; match onscreen labels/glyphs to the actual connected controller; prefer symbols over text.
- UI button mapping: A activates, B cancels/back, shoulders navigate sections, thumbstick/D-pad move selection, Menu pauses/settings, Home reserved for system.
- Keyboard: prefer single-key commands (first letter of menu items, Space for main action).
- Place key bindings near WASD; let players remap bindings.

### drag-and-drop
- Support drag-and-drop broadly (people try it everywhere) and always offer an alternative (menu copy/move).
- Default: same container = move; different container = copy; cross-app = always copy.
- Change defaults only to reduce frustration/data loss.
- Support multi-item drag; on mobile allow adding items to an in-progress drag.
- Prefer allowing undo; confirm before irreversible drops.
- Offer multiple fidelities of dragged content, highest→lowest (e.g. PDF vector → lossless PNG → lossy JPEG); the destination picks the richest it accepts.
- Show a translucent drag image after ~**3 points** of movement.
- Indicate whether a destination accepts the content (insertion point / highlight; show "not allowed" otherwise).
- Animate failed drops back to source or fade out.
- Use drag flocking + a count badge for multi-item drags.
- Auto-scroll the destination while dragging over it.
- Check the Option key at drop time (forces copy within the same container).
- Show progress + a placeholder for slow transfers.
- Keep dropped content selected; apply destination styling when styles don't match.
- Support spring loading (activate controls by hovering/force-clicking while holding content).

---

## UX Patterns

### onboarding
- Ideally the app is self-explanatory; if onboarding is needed, make it fast, fun, and optional.
- Onboarding runs after launch, not during it.
- Teach through interactivity (safe practice beats instructional text).
- Prefer context-specific tips over one big flow; keep prerequisite flows brief and low-memory.
- Make separate tutorials skippable + findable later; don't re-show a skipped tutorial on later launches.
- Provide good defaults so setup/customization can be postponed.
- Integrate a permission request into onboarding only if the app can't function without it.
- Let people experience the app before prompting for ratings/purchases.
- Avoid licensing details and large blocking downloads in the flow.

### launching
- Launch instantly (a couple seconds max).
- Restore previous state (scroll position, windows) so people continue where they left off.
- Launch screen (mobile/TV, not desktop): make it nearly identical to the first screen.
- Launch screen has no text (won't localize), no logos/branding, no advertising — sole purpose is perceived speed.
- Match the launch screen to the current orientation + appearance.
- Launch in the device's current orientation.

### loading
- Show something immediately (placeholder text/graphics/skeletons) so the app doesn't seem broken.
- Let people do other things while content loads in the background.
- For unavoidably long loads, show something interesting (tips, hints, new features) and gauge remaining time.
- Use a determinate progress indicator when duration is known; indeterminate when not.
- Download large assets in the background (after install, during updates, or other nondisruptive times).
- Games may use a custom loading view matching the game's style.

### modality
- Use modality only for clear benefit: critical info, confirming/modifying an action, a narrowly-scoped task, or an immersive focus.
- Keep modal tasks simple and short; avoid an "app within an app" or deep hierarchies.
- Consider full-screen modal for in-depth content/tasks (media, photo editing, markup).
- Always give an obvious dismiss (toolbar button / swipe down on mobile; content-view button on desktop).
- Confirm before dismissing if user content could be lost.
- Title the modal's task to help people keep their place.
- Dismiss one modal before showing another; never show two alerts at once (an alert may sit atop other modals).

### feedback
- Match delivery to significance: passive/inline status for low priority; interrupting alerts for possible data loss.
- Make feedback accessible via multiple channels (color, text, sound, haptics).
- Integrate status feedback near the items it describes.
- Reserve alerts for critical, ideally actionable info (overuse dilutes impact).
- Warn before unexpected + irreversible data loss.
- Do NOT warn when loss is the expected result (e.g. deleting a file).
- Confirm significant/important completions (e.g. a successful transaction).
- Explain why a command can't be carried out.

### entering-data
- Pre-gather info from the system/permissions instead of asking.
- Prefill reasonable defaults; support all input methods (typing, drag-drop, paste).
- Be clear about needed data (placeholder + label).
- Offer choices (picker/menu) over free text when possible.
- Use secure obscured fields for sensitive data; never prepopulate a password field.
- Validate dynamically as people type, showing errors immediately next to the field.
- Use number formatters for numeric/currency data.
- Gate Next/Continue until required data is provided.
- Desktop: use expansion tooltips to show truncated field text.

### searching
- If search is important, make it a primary action (a tab or a visible toolbar field).
- Make content searchable from one clear location.
- Use placeholder text to indicate scope ("Shows, Movies, and More").
- Show the current scope via placeholder/scope control/title.
- Offer recent searches, suggestions, completions, and corrections (before + during typing).
- Respect privacy of search history; let people clear it.
- Make content indexable in systemwide search (metadata) and provide preview generators for custom file types.
- Prefer system open/save views (built-in search).

### settings
- Provide good defaults so most people never adjust anything.
- Minimize the number of settings.
- Make settings reachable where expected (⌘, on desktop, Esc in games).
- Respect systemwide settings; don't duplicate global options (accessibility, scrolling, auth) in-app.
- Put general, infrequently-changed options in a custom settings area.
- Keep task-specific options inline in the screens they affect, not buried in settings.
- Desktop: add a Settings item to the App menu (not the toolbar).
- Desktop: use a stable, noncustomizable settings toolbar with panes; dim minimize/maximize.
- Desktop: update the window title to the active pane (or "App Name Settings"); restore the last-viewed pane.

### managing-accounts
- Require an account only if core functionality demands it.
- Delay sign-in as long as possible (let people explore first).
- Explain the benefits of creating an account in the sign-in view.
- Prefer passkeys (no passwords); otherwise use two-factor.
- Name the exact auth method ("Sign In with Biometric", not generic "Sign In").
- Reference only auth methods available in the current context.
- Don't offer an in-app biometric opt-in (it's a system setting); avoid the word "passcode".
- If people can create an account, they must be able to delete (not just deactivate) it in-app or via a direct, discoverable link.
- Keep in-app and web deletion equivalent in length/complexity.
- Allow scheduling deletion but also offer immediate deletion.
- Tell people when deletion completes; explain subscription billing/cancellation implications.

### managing-notifications
- Requires permission first; people can silence or reschedule.
- Assign an honest interruption level — misusing urgency erodes trust.
- **Passive:** view at leisure; overrides nothing.
- **Active (default):** appreciated on arrival; overrides nothing.
- **Time Sensitive:** immediate; overrides scheduled delivery + breaks through Focus (not Ring/Silent).
- **Critical:** health/safety; also overrides Ring/Silent — requires an entitlement.
- Use Time Sensitive only for things happening now or within an hour.
- Never send marketing/promotional notifications without explicit opt-in.
- Never use Time Sensitive for marketing.
- Provide an in-app screen to manage notification choices.

### offering-help
- Relate help to the exact current task; make it easy to dismiss/avoid.
- Use platform-correct language ("tap" on touch, "click" on desktop).
- Don't explain how standard components work — describe what they do in your app.
- Tips: small transient views for new/less-obvious features; keep to 1–2 sentences, action-oriented, non-promotional.
- Use tips only for features completable in ≤**3 actions**.
- Use eligibility rules (don't show a tip to people who already used the feature).
- Throttle tip frequency (e.g. once every **24 hours**); prefer the filled symbol variant; don't duplicate a UI image.
- Desktop tooltips (help tags): describe only the indicated control, start with a verb, don't repeat the control's name.
- Tooltips: use sentence case; keep to **60–75 characters**.

### file-management
- Provide New/Open via menus + keyboard shortcuts and an Add (+) button.
- If you build a custom file browser, still let people reach the whole file system.
- Autosave periodically and on close/switch — avoid requiring explicit saves.
- Hide file extensions by default but let people show them.
- Use Quick Look to preview files, even ones the app can't open.
- Provide a Quick Look / preview generator for custom file types so other apps can preview them.
- Mobile document launcher: title card (2 buttons), background image, accessories, file-browser sheet — keep app name + both buttons visible; distinct background; animate sparingly.
- Mobile file provider extensions: show only context-appropriate files; no custom top toolbar (the modal already has one).
- Desktop: prefer the default file browser; customize Open/Save (open-recent, filters, format choice, accessory views).
- Desktop: if autosave is off, show an unsaved-changes dot on the close button + Window menu and prompt to save on close/quit.

### undo-and-redo
- Help people predict outcomes: describe the target in an undo alert or label menu items ("Undo Typing", "Redo Bold").
- Show the result (scroll offscreen changes into view) so it doesn't seem like nothing happened.
- Allow multiple undos, up to a logical boundary (open/save).
- Consider batch-reverting related changes.
- Provide dedicated undo/redo buttons only when necessary (use standard symbols in a toolbar).
- Mobile: don't redefine standard undo gestures (three-finger swipe, shake).
- Mobile: alert titles auto-prefix "Undo "/"Redo " — supply a short descriptor.
- Desktop: put commands in the Edit menu; support ⌘Z / ⇧⌘Z.

### multitasking
- Nearly every app must support multitasking; always be ready to save + restore context.
- Pause attention-requiring activities (games, media) when the user switches away; resume seamlessly on return.
- Audio interruptions: pause indefinitely for primary audio (music, podcasts).
- Audio interruptions: duck/pause briefly for short interruptions (GPS) then restore.
- Finish user-initiated background tasks (downloads, exports) before suspending.
- Use notifications sparingly (only for important task completion).
- Tablet: support resizable + multiple windows; adapt to all sizes; support Picture-in-Picture.
- Desktop: multitasking is the default (multiple concurrent windows).

### going-full-screen
- Offer full-screen for focus/immersion (games, media, in-depth tasks).
- Adjust layout subtly for extra space but don't programmatically resize the window.
- Keep essential controls available or easy to reveal.
- Except in games, let people reveal system UI (preserve access to other apps).
- Pause on switch-away and resume on return; let people choose when to exit (don't auto-exit).
- Reveal hidden toolbars/nav via a familiar gesture (tap, swipe down, cursor-to-top).
- Mobile: defer system gestures to prevent accidental exits (allow two swipes instead of one if needed).
- Desktop: use the system full-screen experience (Enter Full Screen button / View menu / ⌃⌘F).
- Desktop games: don't change the display mode on entering full screen.

### collaboration-and-sharing
- Keep it simple and responsive.
- Place the Share button in a convenient spot (toolbar); use the system share sheet / sharing popover to choose method + permissions.
- Write succinct permission summaries ("Only invited people can edit").
- Keep custom sharing options minimal and grouped.
- Show the system Collaboration button as soon as collaboration starts (next to Share) — it identifies participants.
- Keep the collaboration popover's custom actions to the essentials (top: collaborators/comms; middle: your items; bottom: manage-file).
- Post collaboration event notifications with universal links.
- Available on mobile + desktop only.

### ratings-and-reviews
- Deliver a great experience first; ask for a rating only after demonstrated engagement (completed level/task).
- Never ask on first launch or during onboarding.
- Don't interrupt active tasks — ask at natural stopping points.
- Don't pester; allow at least a week or two between requests.
- Prefer the system prompt (single tap, users can opt out).
- System prompt is limited to **3 per app per 365 days**.
- Resetting the summary rating on a new version makes ratings current but reduces total count — weigh the tradeoff.

### writing
- Establish a consistent voice; vary tone by context.
- Be clear and concise (cut unneeded words; read aloud).
- Write for everyone: plain language, no jargon/gendered terms, localization-friendly.
- Put the most important info first.
- Be action-oriented — label buttons/links with verbs ("Send", "Learn more about UX Writing", not "Let's do it!"/"Click here").
- Choose title vs. sentence case per element type and apply it consistently (title = formal, sentence = casual).
- Use consistent step language ("Get Started" → "Continue"/"Next" → "Done").
- Use possessive pronouns sparingly ("Favorites" not "Your Favorites"); avoid "we".
- Match verbs to the device ("tap" vs. "click").
- Empty states: guide next steps with a button/link.
- Error messages: display near the problem; avoid blame and "oops"/"uh-oh"; say how to fix it ("Choose a password with at least 8 characters").
- Keep settings labels clear (describe the on-state); link directly to a setting rather than describing its location.
- Show hint/placeholder text with a format example ("name@example.com").

### charting-data
- Use a chart to highlight important info; not all data needs one (a list/table may suffice).
- Keep charts simple; reveal detail progressively (levels, subsets).
- Make every chart accessible: provide accessibility labels for values/components plus interactive accessibility elements.
- A descriptive headline doesn't replace accessibility labels.
- Prefer common chart types (bar, line); teach novel chart types (e.g. animate their meaning).
- Add descriptive titles/subtitles/annotations to emphasize takeaways.
- Size the chart to its detail + interactivity needs.
- Keep multiple charts consistent (type, color, layout, annotations), especially when sharing a dataset; deviate only to highlight meaningful differences.

### printing
- Make printing discoverable in standard locations (desktop File menu; mobile toolbar/action sheet).
- Present the option only when possible (dim/remove when nothing to print or no printers).
- Show relevant options (page range, copies, duplex) via the system view.
- Desktop: add a custom print-panel category for app-specific options; offer a page setup dialog without reimplementing system options.
- Desktop: make option interdependencies clear; hide advanced options behind a disclosure; consider preview + storing settings with the document.

---

## Media

### playing-audio
- Respect silent mode (play only user-initiated audio: media, alarms, A/V messages).
- Respect system volume — adjust only relative/independent levels, never overall volume.
- Reroute automatically when headphones connect; pause immediately when they disconnect.
- **Solo Ambient:** nonessential; silences other audio; obeys silence switch; no background.
- **Ambient:** nonessential; mixes with others; obeys silence switch; no background.
- **Playback:** essential; may mix; ignores silence switch; can play in background.
- **Record** / **Play and Record:** ignore silence switch; can run in background.
- Respond to external audio controls only when it makes sense (actively playing / audio context / connected wireless device).
- Never repurpose or redefine audio controls; only add custom controls for commands the system lacks.
- Flag your session so other apps can resume; decide auto-resume based on interruption type (resumable vs. not).

### playing-video
- Use the system video player for a familiar experience; reference it closely if you must build custom.
- Always display video at its original aspect ratio — no embedded letterbox/pillarbox padding (breaks scaling + PiP).
- Default modes: full-screen (aspect-fill) for wide video (2:1–2.40:1); fit-to-screen (aspect) for standard (4:3, 16:9, up to 2:1) + ultrawide (>2.40:1).
- Support Space to play/pause on any keyboard.
- Avoid mixing audio from different sources across mode switches.
- Integrated video service: fade to black then jump straight into content — no launch/splash/detail screens; auto-resume without prompting (use previous end time); switch to the correct user profile.
- Loading: avoid loading screens; if load >**2 seconds**, show a black screen with a centered spinner and minimal branding.
- Start playback as soon as enough content loads; on exit show a contextually relevant detail/menu screen; be ready for an immediate exit.

### playing-haptics
- Use system haptic patterns per their documented meaning; don't repurpose them.
- Keep haptics consistent (build a clear cause-and-effect association).
- Keep haptics complementary to visual/audio feedback (match intensity + sharpness).
- Don't overuse; make haptics optional; ensure the app works without them.
- Avoid disrupting camera/gyroscope/microphone with haptic vibration.
- Prefer short haptics for discrete events; avoid long-running haptics in non-game apps.
- Mobile **Notification** patterns: success / warning / error.
- Mobile **Impact** patterns: light / medium / heavy / rigid / soft.
- Mobile **Selection** pattern: value changing.
- Custom haptics combine **transient** (taps/impulses) + **continuous** (sustained) events, varied by **sharpness** + **intensity**.
- Desktop haptic patterns: alignment, level change, generic.

### live-viewing-apps
- Prioritize live content: feature it prominently (first tab; one tap or zero to start).
- Use a Watch Now button that disappears into full-screen playback.
- Make live content look/feel live and distinguishable from VOD (badge/symbol/sash; show progress of in-progress content).
- Order actions consistently (e.g. Watch, Start Over, Record, Favorite).
- Give instant visual feedback on channel change (confirms arrival + masks load time).
- Match audio to context — stop audio when leaving the live tab.
- EPG: surface current program/channel/time and easy return to playback; make browsing effortless (paging, favorites).
- EPG: group into familiar categories (Movies, TV, Kids, Sports); allow browsing (PiP/background) without leaving content.
- Content footer: subtle darkening, badge the current thumbnail, symmetrical invoke/dismiss gesture.
- Cloud DVR: start/stop from the info panel; record single/all episodes; allow playback/delete/settings; offer automatic storage management.

---

## Technologies

### apple-pay
- Payments for physical goods/services/donations/subscriptions — NOT virtual goods (see in-app-purchase).
- Offer only on supporting devices.
- If you check for an active card, make Apple Pay the primary (not necessarily sole) option, at least as prominent as others.
- Use the system API to render the Pay button (correct appearance, auto-localized caption, configurable corner radius).
- Custom buttons must not show "Apple Pay" or the logo — use the mark or text instead.
- Buttons only start the pay/setup flow.
- Don't hide/disable the button — surface problems (e.g. unselected size) after a tap.
- Streamline checkout: integrated, no new windows/pages; present Pay first/larger.
- Collect required options + optional info + multi-destination shipping before showing the payment sheet.
- Prefer info from Apple Pay; don't require account creation before purchase.
- Payment sheet: request only essential info; use line items for extra charges/discounts/recurring (short, single-line, not a product list).
- Pay line: "Pay [Business_Name]" (or "Pay [End_Merchant] (via [You])" when an intermediary).
- Disclose pending/variable amounts ("Amount Pending").
- Error messages: noun phrases, sentence case, no ending punctuation, specific ("Zip code doesn't match city"), ≤**128 characters**.
- Website icon sizes **60x60pt** (120x120px @2x, 180x180px @3x).
- Button minimum **width 100pt** (140pt for longer captions), **height 30pt**, margins **1/10 of height**.
- Pay mark clear space **1/10 of its height**.
- Button styles: black (light bg), white-with-outline (light bg, low contrast), white (dark bg).
- Layout: side-by-side → Pay right of Add-to-Cart; stacked → Pay above.
- Never redesign or mimic the button; write "Apple Pay" exactly (two words, don't translate/pluralize).

### in-app-purchase
- Virtual goods: premium content, digital goods, subscriptions.
- Four types: consumable, non-consumable, auto-renewable subscription, non-renewing subscription.
- Let people experience the app before purchasing (offer limited free access for subscriptions).
- Design an integrated store that matches app style; use simple non-truncating product names.
- Always show the total billing price; hide the store when payments aren't possible.
- Use the default system confirmation sheet — don't modify/replicate it.
- Family Sharing: mention it where people learn about content ("Family"/"Shareable"); customize messaging for purchasers vs. members.
- Refunds: provide in-app help before the system refund flow; simple action title ("Refund"); help identify the purchase.
- Refunds: offer alternatives but never block the refund; don't editorialize policy.
- Subscriptions: show value during onboarding with clear terms; offer a range of durations/levels; allow free trials with clear post-trial billing.
- Subscriptions: prompt at relevant moments; don't push a new subscription to existing subscribers.
- Sign-up screen must show name/duration/content, localized price, and a sign-in/restore option.
- Support in-app upgrade/downgrade/cancel — always make canceling easy.
- Mobile offer codes: one-time-use or custom (alphanumeric ASCII only); explain redemption.

### maps
- Make maps interactive (zoom/pan/rotate); don't obscure with noninteractive elements.
- Emphasis style: **default** (saturated, standard use) or **muted** (desaturated, for info-rich overlays).
- Offer search + category filters; clearly style selected elements; cluster overlapping POIs at low zoom.
- Keep attribution + legal link visible: ~**7pt** side padding, ~**10pt** above/below.
- Keep attribution fixed to the map; place **10pt** above the lowest resting position of movable custom UI.
- Attribution/link not shown on maps smaller than **200x100px**.
- Custom annotations match app style; icon string 2–3 chars for legibility.
- Overlays: **above roads** (default, below buildings) or **above labels** (hides everything beneath).
- Ensure enough contrast for custom controls over the map (thin stroke / light shadow).
- Place cards (hours, phone, address) styles: automatic / callout (full or compact) / caption ("Open in Maps") / sheet.
- Choose card style by map size + avoid duplicating info; keep the location visible.
- If a place card is outside a map view it must include a map.
- Indoor maps: adjust detail by zoom; distinctive styling per area type; floor picker (concise numbers).
- Indoor maps: include dimmed surrounding context; limit outside scrolling; feel like a natural extension of the app (don't clone standard Maps).

### machine-learning
- Design the model as carefully as the UI; you teach interpretation rather than scripting fixed reactions.
- Characterize each feature: critical vs. complementary, private vs. public, proactive vs. reactive, visible vs. invisible, dynamic vs. static.
- More critical/sensitive/proactive → demands higher accuracy + reliability.
- Prefer **implicit** feedback (from behavior) over **explicit** (asked for); make explicit feedback voluntary.
- Describe explicit-feedback options by consequence ("Suggest less pop music", not "dislike").
- Act immediately on feedback and persist changes; secure all feedback data.
- Don't let implicit feedback kill exploration or leak private/sensitive suggestions; prioritize recent feedback; use multiple signals to avoid misreading intent.
- Calibration: use only when the feature can't function without it; collect minimal info; ask once, early; explain why; show progress + confirm success; allow cancel and later edits.
- Corrections: familiar + easy; provide immediate value + persist; prefer guided over freeform.
- Mistakes are inevitable — anticipate, help recover proportionally to severity, learn only when it improves results; be extra careful with proactive features.
- Confidence: verify it correlates with quality before showing; translate into understandable concepts/categories ("high chance") or actionable suggestions ("This is a good time to buy"); hide low-confidence proactive results.
- Attribution: explain the basis ("Because you listen to pop music") without exposing model internals; balance specific vs. general; keep factual, no emotional judgment/jargon.
- Multiple options: prefer diverse; avoid too many; list most-likely first; make options distinguishable.

### generative-ai
- Design responsibly (inclusive, careful, privacy-protecting); expect the same input to yield different outputs.
- Keep people in control — honor in-scope requests; let them dismiss/revert/retry; clearly identify where AI is used.
- Ensure inclusive results (test across diverse people; ask rather than infer personal/cultural traits).
- Offer a non-AI fallback where possible.
- Transparency: disclose AI use; never make AI content seem human-authored; set clear capability/limitation expectations; offer example prompts.
- Privacy: prefer on-device processing (faster, offline, keeps data local).
- Privacy: if server-based, process locally first + minimize what's shared + show what's shared.
- Privacy: ask permission before using personal/usage data, use the minimum, allow opt-out; kids' apps have stricter rules.
- Outputs: raise awareness of hallucinations (state content may contain errors; scope tightly; avoid factual generation unless verified; never where a hallucination could harm).
- Outputs: confirm before destructive/hard-to-undo actions; avoid replicating copyrighted content.
- Outputs: factor in latency (background/loading experience); consider offering multiple result versions.
- Improvement: update over time (blocklists frequently, big changes with app updates); make feedback voluntary + non-intrusive (thumbs up/down); keep the model swappable/decoupled from UX.

### augmented-reality
- Mobile only. Offer AR only on capable devices; don't error on unsupported ones — just omit the feature.
- Devote as much of the display as possible to the world + virtual objects; minimize clutter/controls/text.
- Strive for convincing illusions: lifelike 3D assets, proper scale on detected surfaces, environmental lighting + camera grain, top-down diffuse shadows.
- Update scenes **60 times per second** to avoid jump/flicker.
- Prefer small/coarse reflective surfaces; enhance with audio + haptics.
- Put persistent controls/critical text in **screen space** (2D, stationary, reachable); use translucency so indirect controls don't block the scene.
- Comfort/safety: place objects to reduce device movement; introduce motion gradually; avoid encouraging rapid/sweeping/dangerous movements.
- Use the system coaching view for initialization + relocalization (after interruptions); hide unrelated UI during coaching.
- Integrate placed objects instantly, then subtly refine position when surface detection completes.
- Don't align precisely to surface edges (they're approximate); use plane classification (floor/table) to constrain placement.
- Interactions: prefer direct manipulation with familiar gestures (single-finger drag = move, two-finger rotate = spin).
- Keep interactions simple (limit to 2D surface / single-axis rotation); respond within reasonable proximity; watch for conflicting gestures (pinch vs. rotate).
- Don't use scaling to fake distance.
- Real-world detection: delay removing objects up to **1 second** when a detected image disappears (prevents flicker).
- Use **≤100** reference images at once.
- Use friendly language ("Unable to find a surface. Try moving to the side..."); prefer 3D hints in a 3D context.
- AR glyph/badge: only to launch/identify AR; never alter beyond size/color.
- Maintain clear space of **10% of glyph/badge height**; badge only when the app mixes AR + non-AR objects.
