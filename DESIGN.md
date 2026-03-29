# Timeless — Design System & Website Redesign Spec

This document captures the visual identity established for the Timeless brand (YouTube banner,
channel icon) and defines how it should be applied to the website redesign. Hand this to
Claude Code to guide the overhaul of `timeless_web`.

---

## Brand Identity

**Product:** Timeless — embedded observability stack for Elixir/Phoenix  
**Tagline:** Observability Made Simple  
**Sub-tagline:** Embedded observability for Elixir & Phoenix  
**Audience:** Elixir/Phoenix developers, small-to-mid teams, open source community  
**Tone:** Technical, confident, clean — not corporate. Think tool-maker, not enterprise vendor.

---

## Logo

The Timeless logo is an infinity/figure-8 symbol (representing timeless data, continuous
observability) paired with the wordmark "TIMELESS" in Trebuchet MS.

### Infinity mark SVG path (exact):
```svg
<path d="M8 2C4.5 2 2 4.7 2 8s2.5 6 6 6c2.2 0 4-1.2 5.5-3L14 10.5l.5.5c1.5 1.8 3.3 3 5.5 3 3.5 0 6-2.7 6-6s-2.5-6-6-6c-2.2 0-4 1.2-5.5 3L14 5.5 13.5 5C12 3.2 10.2 2 8 2z"
  fill="none" stroke="..." stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
```

The path is defined in a `viewBox="0 0 28 16"` coordinate space. Scale it with `transform`.

### Logo color treatments:
- **On dark backgrounds:** gradient stroke from `#c4b5fd` → `#6366f1` → `#a78bfa` (use SVG linearGradient)
- **On light backgrounds:** solid `#6366f1`
- **Wordmark:** Trebuchet MS, font-weight 700, letter-spacing 0.2em

---

## Color Palette

### Primary Brand Colors
| Name | Hex | Usage |
|------|-----|-------|
| Indigo core | `#6366f1` | Primary accent, CTAs, links, borders |
| Indigo light | `#818cf8` | Secondary accent, hover states |
| Indigo pale | `#a5b4fc` | Taglines, subheadings on dark |
| Violet | `#7c3aed` | Gradient partner to indigo |
| Lavender | `#c4b5fd` | Logo gradient start, highlights |
| Near-white | `#e0d9ff` | High-contrast text on dark |

### Background Layers (dark theme — the primary theme)
The site uses a **deep space dark background** — not a flat solid color but a layered radial
gradient system:

```css
/* Base background — use as body/page background */
background: radial-gradient(ellipse at 50% 40%, #160932 0%, #07031a 55%, #020108 100%);

/* Glow layer — overlay on hero sections */
/* Use as a pseudo-element or absolute div */
background: radial-gradient(ellipse 80% 60% at 50% 40%, 
  rgba(99,102,241,0.35) 0%, 
  rgba(124,58,237,0.10) 55%, 
  transparent 100%);

/* Dot texture — subtle grid overlay */
/* SVG pattern: circles r=0.5 at 13,13 in a 26x26 tile, fill #818cf8 opacity 0.15 */

/* Vignette — darkens edges */
background: radial-gradient(ellipse at 50% 50%, transparent 0%, rgba(0,0,0,0.6) 100%);
```

### Text Colors on Dark
| Role | Value |
|------|-------|
| Headings / primary | `#ffffff` or `#e0d9ff` |
| Body text | `#94a3b8` (slate-400) |
| Muted / meta | `#64748b` (slate-500) |
| Accent links | `#818cf8` |
| Active / hover links | `#a5b4fc` |

### Card / Surface Colors
```css
/* Card background */
background: rgba(255,255,255,0.03);
border: 1px solid rgba(99,102,241,0.15);
border-radius: 12px;

/* Card hover */
background: rgba(99,102,241,0.06);
border-color: rgba(99,102,241,0.35);
```

### Gradient Accents
```css
/* Divider lines — fade in and out */
background: linear-gradient(90deg, 
  transparent 0%, 
  rgba(99,102,241,0.9) 20%, 
  rgba(139,92,246,0.9) 80%, 
  transparent 100%);

/* Text gradient — for hero headings */
background: linear-gradient(90deg, #a5b4fc 0%, #dde4ff 25%, #ffffff 50%, #dde4ff 75%, #a5b4fc 100%);
-webkit-background-clip: text;
-webkit-text-fill-color: transparent;

/* Logo gradient */
background: linear-gradient(135deg, #c4b5fd 0%, #6366f1 50%, #a78bfa 100%);
```

---

## Typography

**Primary font:** Trebuchet MS (already in use — keep it, it matches the logo wordmark perfectly)  
**Fallback stack:** `'Trebuchet MS', 'Gill Sans MT', Helvetica, Arial, sans-serif`  
**Mono font:** existing system mono for code blocks

### Type Scale
| Element | Size | Weight | Treatment |
|---------|------|--------|-----------|
| Hero heading | 3.5–4.5rem | 700 | Gradient text or pure white |
| Section heading | 2–2.5rem | 700 | White |
| Card heading | 1.1–1.25rem | 600 | White or `#a5b4fc` |
| Body | 1rem | 400 | `#94a3b8` |
| Eyebrow label | 0.7rem | 600 | `#6366f1`, letter-spacing 0.15em, uppercase |
| Tagline / sub | 0.85rem | 400 | `#a5b4fc`, letter-spacing 0.15em |

### Key rule: 
Eyebrow labels (like "OPEN SOURCE OBSERVABILITY FOR PHOENIX") should use the indigo accent 
color — they're currently a flat gray that disappears into the background.

---

## Atmosphere & Effects

### Hero section
- Full-viewport-height or near (min-height: 90vh)
- Deep space radial gradient background
- Indigo glow bloom centered behind the logo/heading
- Subtle dot pattern overlay (very low opacity)
- The infinity mark should appear LARGE and centered or left-aligned behind/above the headline
  as an atmospheric element — treat it like a brand watermark, not just a nav icon
- Faint concentric rings radiating from the logo center (circles with very low opacity strokes)

### Waveform decoration
The banner features faint time-series waveform lines in the lower portion — apply this to 
the hero section footer area as an atmospheric element suggesting data/metrics:
```
Polyline: 0,100% → irregular points → 100%,90%
stroke: gradient (indigo → transparent)
opacity: 0.10–0.15
```

### Cards
- Replace flat `border border-gray` cards with the glassmorphism treatment above
- Add a very subtle gradient border on hover: `border-color: rgba(99,102,241,0.4)`
- No heavy shadows — use border glow instead
- Eyebrow tags (like `timeless_phoenix`, `Featured`) should use indigo pill style:
  ```css
  background: rgba(99,102,241,0.15);
  border: 1px solid rgba(99,102,241,0.3);
  color: #a5b4fc;
  border-radius: 9999px;
  padding: 2px 10px;
  font-size: 0.75rem;
  ```

### Buttons
```css
/* Primary CTA */
background: #6366f1;
color: white;
border-radius: 8px;
padding: 10px 20px;
font-weight: 600;
transition: background 0.2s;
hover: background: #818cf8;

/* Secondary / outline */
background: transparent;
border: 1px solid rgba(99,102,241,0.4);
color: #a5b4fc;
hover: border-color: #6366f1; background: rgba(99,102,241,0.08);

/* Ghost / text link */
color: #818cf8;
hover: color: #a5b4fc;
```

---

## Navigation

**Current:** Minimal nav with logo left, links center, auth right. Fine structurally.

**Changes:**
- Logo mark should be slightly larger (24–28px tall) with the gradient stroke treatment
- "TIMELESS" wordmark: increase letter-spacing slightly, use gradient or pure white
- Nav background: `rgba(2,1,8,0.8)` with `backdrop-filter: blur(12px)` — frosted glass effect
- Nav border-bottom: `1px solid rgba(99,102,241,0.1)`
- Active/hover nav links: `#a5b4fc` instead of plain white
- Sticky nav on scroll

---

## Page Sections — Redesign Notes

### Hero (above the fold)
**Current:** Left-aligned text + right terminal card. Looks like a template starter.  
**Redesign:**
- Full-width, centered layout
- Large infinity mark as hero visual (SVG, ~200–300px, gradient stroked, with glow halos)
- Below the mark: "TIMELESS" in large gradient text (or bold white)
- Tagline: "Observability Made Simple" in `#a5b4fc`, letter-spaced
- Sub-copy: one sentence max, muted slate color
- CTA buttons centered below
- Terminal/code block can remain but float below or alongside — make it feel like a
  product demo, not the hero itself
- Background: full deep-space gradient treatment

### "Two ways to use the stack" section
**Current:** Three flat dark cards, indistinguishable from each other.  
**Redesign:**
- Keep the three cards but apply glassmorphism + gradient border
- Card headings in white, descriptions in slate-400
- Each card gets a subtle indigo accent: left border `2px solid #6366f1` OR
  a small indigo icon/symbol top-left
- Section eyebrow: "PRODUCT SHAPE" → keep but style in indigo
- Section heading: larger, white, more weight

### Projects section
**Current:** Three project cards with colored title links.  
**Redesign:**
- Same glassmorphism card treatment
- Package name tags: indigo pill style (see above)
- "Featured" badge: more prominent — solid indigo pill
- Card titles: white, larger
- "Read more" / "Repo" links: `#818cf8` with arrow →

### Blog / Journal section
**Current:** Three cards, identical treatment to projects — feels repetitive.  
**Redesign:**
- Different layout from projects — use a slightly different card shape or arrangement
  to give the page more visual rhythm
- Date + "Featured" meta in muted/indigo
- Titles: white, hover → `#a5b4fc`

### Dashboard CTA section
**Current:** Wide card with text left, buttons right. Very plain.  
**Redesign:**
- Give this section its own indigo glow treatment — it should feel like a highlight
- Gradient border or indigo-tinted background
- Make it feel like a feature highlight, not an afterthought

### Footer
**Current:** Simple two-line footer.  
**Redesign:**
- Add the infinity mark watermark (very faint, large, centered behind footer text)
- Links in `#64748b`, hover `#a5b4fc`
- "BUILT WITH TIMELESS" eyebrow in indigo

---

## What NOT to change

- The overall page structure and content — it's well organized
- Navigation items (Projects, Blog, Dashboard)
- The terminal/code block in the hero — good product storytelling, just needs styling
- The copy — it's good, leave it alone
- Light/dark mode toggle — keep it, but the dark mode is the primary brand mode

---

## Reference Assets

The following files were created during the brand session and live in the project:

- `timeless_banner.jpg` — 2560×1440 YouTube banner (reference for background treatment,
  typography, and overall vibe)
- `timeless_icon.svg` — Channel icon / logo mark in the circular deep-space treatment
- `logo-light.svg` — Original logo SVG (source of the infinity path and Trebuchet wordmark)

The YouTube banner is the **north star reference** for the website aesthetic. The site should
feel like you're browsing inside that banner — same atmosphere, same colors, same typography
personality, applied to a multi-section product page.

---

## Implementation Notes for Claude Code

1. This is a Phoenix/LiveView project using Tailwind CSS
2. Main templates likely in `lib/timeless_web/components/` and `lib/timeless_web/controllers/`
   or `lib/timeless_web/live/`
3. CSS in `assets/css/app.css` — add CSS custom properties for the color palette
4. The background gradient should be on the `body` or a root layout wrapper, not per-section
5. Add the dot pattern as a CSS background using an SVG data URI:
   ```css
   background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='26' height='26'%3E%3Ccircle cx='13' cy='13' r='0.5' fill='%23818cf8' opacity='0.15'/%3E%3C/svg%3E");
   ```
6. The glow bloom behind the hero can be a simple `<div>` with `position: absolute`,
   `pointer-events: none`, and the radial gradient — no JS needed
7. For the infinity mark logo at hero scale, use an inline SVG with an explicit linearGradient
   defs block rather than referencing the external SVG file (gradients don't work cross-file)
8. Tailwind dark mode: the site already uses dark mode — lean into it as the default
9. Keep changes incremental: start with `app.css` custom properties + body background,
   then tackle the hero, then cards, then details

---

## Prompt for Claude Code

Use this to kick off the session:

```
I have a design spec at DESIGN.md in the project root. Please read it fully before starting.

The goal is to redesign the Timeless website homepage to match the brand identity described —
deep space dark background with indigo/violet glow, the infinity mark as a prominent hero
element, glassmorphism cards, and the overall atmosphere of the YouTube banner we created.

Start by reading DESIGN.md, then survey the template files, then propose a plan before
making changes. Work section by section — hero first, then cards, then footer.
```
