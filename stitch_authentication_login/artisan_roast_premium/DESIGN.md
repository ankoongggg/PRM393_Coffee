# Design System: High-End Coffee Management Editorial

## 1. Overview & Creative North Star: "The Modern Roastery"
This design system moves beyond functional utility into the realm of a premium lifestyle editorial. Our Creative North Star is **"The Modern Roastery"**—a concept that balances the industrial precision of coffee brewing with the organic, warm atmosphere of a high-end cafe.

Instead of a rigid, "app-like" grid, we utilize **intentional asymmetry** and **tonal layering**. We reject the "template" look by treating every screen as a composition of fine paper and frosted glass. High-contrast typography scales (the juxtaposition of the expansive *Manrope* and the technical *Inter*) create an authoritative yet inviting hierarchy that feels bespoke rather than off-the-shelf.

---

## 2. Colors & Surface Philosophy
The palette is grounded in the warmth of raw parchment and the depth of roasted beans, punctuated by functional "role-based" accents.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders for sectioning. Boundaries must be defined solely through:
1.  **Background Shifts:** e.g., A `surface-container-low` section sitting on a `surface` background.
2.  **Tonal Transitions:** Using the hierarchy of `surface-container` tiers to imply edges.
3.  **Soft Negative Space:** Utilizing the spacing scale to let the eye define the grouping.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. Each inner container should use a slightly higher or lower tier to define its importance:
*   **Lowest Layer:** `surface` (#fbf9f5) – The main canvas.
*   **Intermediate Layer:** `surface-container` (#efeeea) – Primary content areas.
*   **Elevated Layer:** `surface-container-lowest` (#ffffff) – Used for high-priority cards to create a "pop" against the warmer background.

### The "Glass & Gradient" Rule
To elevate the experience, use **Glassmorphism** for floating elements (like navigation bars or active order overlays). Use semi-transparent surface colors with a `backdrop-filter: blur(20px)`.
*   **Signature Textures:** Apply subtle linear gradients from `primary` (#361f1a) to `primary-container` (#4e342e) on main CTAs to provide a tactile "roasted" depth.

---

## 3. Typography: The Editorial Contrast
We use a dual-font strategy to balance character with readability.

*   **Display & Headlines (Manrope):** These are our "hero" moments. Use `display-lg` and `headline-md` with generous tracking to give the app an expensive, spacious feel.
*   **Body & Labels (Inter):** This is our "workhorse." Use `body-md` for order details and `label-sm` for technical metadata (timestamps, table numbers).
*   **The Hierarchy Goal:** Use extreme scale differences. A large `display-sm` header next to a tiny, all-caps `label-md` creates an "Architectural" layout that looks intentional and premium.

---

## 4. Elevation & Depth
We eschew traditional "material" shadows in favor of **Tonal Layering**.

*   **The Layering Principle:** Stack `surface-container-lowest` cards on `surface-container-low` backgrounds to create a soft, natural lift without a single pixel of shadow.
*   **Ambient Shadows:** When a "floating" effect is mandatory (e.g., a modal), use an extra-diffused shadow: `box-shadow: 0 20px 40px rgba(54, 31, 26, 0.06)`. The tint is derived from our `primary` coffee brown, not grey.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, use the `outline-variant` token at **15% opacity**. Never use 100% opaque lines.
*   **Decorative Blurs:** Inject "visual soul" by placing large, low-opacity blur circles of `secondary_fixed` (green) and `tertiary_fixed` (blue) behind the main content layers to subtly signify Waiter or Barista zones.

---

## 5. Components & Primitive Styling

### Buttons (The Tactile Touch)
*   **Primary:** Gradient from `primary` to `primary_container`. Border radius: `xl` (1.5rem). No shadow, unless hovered.
*   **Secondary (Waiter/Barista):** Use `secondary_container` (for Waiters) or `tertiary_container` (for Baristas) with `on_container` text. These should feel like soft fabric tags.
*   **Tertiary:** Ghost style. No background, `label-md` typography, with a `surface-variant` hover state.

### Cards & Lists (The Order Flow)
*   **Rule:** Forbid the use of divider lines.
*   **List Items:** Separate items using `2.5` (0.85rem) of vertical white space or by alternating between `surface` and `surface-container-low`.
*   **Cards:** Use `xl` (1.5rem) corner radius. Apply a subtle `outline-variant` ghost border at 10% opacity for "nested" feel.

### Input Fields (Professional Precision)
*   **Styling:** Background-fill using `surface-container-high`. No bottom line.
*   **Focus State:** Shift background to `surface-container-highest` and add a 1px ghost border using `primary` at 20% opacity.

### Role-Specific Indicators (The Coffee Logic)
*   **Waiter Chips:** Use `secondary_fixed_dim` for a soft, earthy green that feels organic, not neon.
*   **Barista Status:** Use `tertiary_fixed_dim` for a clean, technical blue that represents the precision of the machine.

---

## 6. Do’s and Don’ts

### Do:
*   **Do** use asymmetrical margins. A wider left margin for headers creates an editorial "lookbook" feel.
*   **Do** lean into the "Warm Light" (#FDFBF7) background. It reduces eye strain and feels more premium than pure white.
*   **Do** use `20` (7rem) spacing for major section breaks to let the design breathe.

### Don’t:
*   **Don’t** use 1px solid dividers. If you feel you need a line, use a 12px gap instead.
*   **Don’t** use pure black (#000000). Always use `on_background` (#1b1c1a) for text to maintain the warm, organic tone.
*   **Don’t** use standard "Material" shadows. If it looks like a default shadow, it’s too heavy.