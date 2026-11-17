# Voltaic Light

Warm off-white paper with a deep olive accent. The light flavour of the user's personal theme.

## Colour Palette

### Backgrounds and text

| Name      | Hex       | Use for                                           |
| --------- | --------- | ------------------------------------------------- |
| `base`    | `#f0efed` | Page background                                   |
| `deep`    | `#faf9f7` | Code blocks, canvas areas, text on an accent fill |
| `surface` | `#ffffff` | Cards, panels, table header rows                  |
| `overlay` | `#e4e4e7` | Borders, dividers, hover                          |
| `muted`   | `#d4d4d8` | Rules, separators                                 |
| `dim`     | `#a1a1aa` | Disabled and placeholder text                     |
| `subtle`  | `#6c6c75` | Captions, de-emphasised text                      |
| `soft`    | `#52525b` | Secondary text, labels                            |
| `text`    | `#3f3f46` | Body text                                         |
| `bright`  | `#27272a` | Headings, emphasised text                         |

### Accents

| Name    | Hex       | Use for                                                      |
| ------- | --------- | ------------------------------------------------------------ |
| `volt`  | `#4c790f` | Signature accent: fills, buttons, focus rings, brand moments |
| `arc`   | `#3f6212` | Accent text and icons                                        |
| `blue`  | `#1d4ed8` | Links, information                                           |
| `jade`  | `#047857` | Success                                                      |
| `amber` | `#9c5f07` | Warning                                                      |
| `ember` | `#be123c` | Error                                                        |

Rules:

- Accent text uses `arc`, not `volt`. Reserve `volt` for shapes, and put `deep` text on a `volt` fill.
- Use `volt` sparingly. It works because everything around it is grey.
- Success is `jade`, not `volt`.
- For translucent fills, use only these opacities: 8%, 14%, 20%, 30% and 50%. Never put text on the 50% fill.
- Body text must keep at least 4.5:1 contrast against its background.

### Charts

Series that mean a state take the status colours: `jade`, `amber`, `ember`. Other series take this order, and stop when you have enough: `blue`, `teal` `#0f766e`, `bronze` `#92400e`, `ice` `#52525b`, `lilac` `#8b5cf6`.

Never use `volt` or `arc` as a series colour. Grid lines use `overlay`, and axis labels use `soft`.

## Typography

| Font           | Use for                   | Weight     |
| -------------- | ------------------------- | ---------- |
| Clash Display  | Titles and hero headlines | 400        |
| Clash Grotesk  | Section headings          | 500        |
| Geist          | Body text                 | 400 to 500 |
| JetBrains Mono | Code, labels, metadata    | 400        |

Clash Display and Clash Grotesk come from Fontshare. Geist comes from Vercel. JetBrains Mono is open source. Use no more than three of these in one piece of output.

```css
--font-display: "Clash Display", "Inter", system-ui, sans-serif;
--font-heading: "Clash Grotesk", "Inter", system-ui, sans-serif;
--font-body: "Geist", "Inter", system-ui, sans-serif;
--font-mono: "JetBrains Mono", "Geist Mono", monospace;
```

Keep display type at normal weight, not bold. Mono labels are uppercase with wide letter-spacing (0.15em).

## Best Used For

Print, documents and PDFs that represent the user personally, or any personal output where the user asks for light.
