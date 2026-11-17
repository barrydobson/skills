# Voltaic Dark

Near-black zinc with an electric lime accent. The user's personal theme, and the default for anything that represents them personally.

## Colour Palette

### Backgrounds and text

| Name      | Hex       | Use for                                           |
| --------- | --------- | ------------------------------------------------- |
| `base`    | `#09090b` | Page background                                   |
| `deep`    | `#0c0a09` | Code blocks, canvas areas, text on an accent fill |
| `surface` | `#18181b` | Cards, panels, table header rows                  |
| `overlay` | `#27272a` | Borders, dividers, hover                          |
| `muted`   | `#3f3f46` | Rules, separators                                 |
| `dim`     | `#52525b` | Disabled and placeholder text                     |
| `subtle`  | `#787881` | Captions, de-emphasised text                      |
| `soft`    | `#a1a1aa` | Secondary text, labels                            |
| `text`    | `#d4d4d8` | Body text                                         |
| `bright`  | `#fafafa` | Headings, emphasised text                         |

### Accents

| Name    | Hex       | Use for                                                      |
| ------- | --------- | ------------------------------------------------------------ |
| `volt`  | `#c8ff00` | Signature accent: fills, buttons, focus rings, brand moments |
| `arc`   | `#a3e635` | Accent text and icons                                        |
| `blue`  | `#7aa2f7` | Links, information                                           |
| `jade`  | `#10b981` | Success                                                      |
| `amber` | `#e0af68` | Warning                                                      |
| `ember` | `#f7768e` | Error                                                        |

Rules:

- Accent text uses `arc`, not `volt`. Reserve `volt` for shapes, and put `deep` text on a `volt` fill.
- Use `volt` sparingly. It works because everything around it is grey.
- Success is `jade`, not `volt`.
- For translucent fills, use only these opacities: 8%, 14%, 20%, 30% and 50%. Never put text on the 50% fill.
- Body text must keep at least 4.5:1 contrast against its background.

### Charts

Series that mean a state take the status colours: `jade`, `amber`, `ember`. Other series take this order, and stop when you have enough: `blue`, `teal` `#73daca`, `bronze` `#b9a58c`, `ice` `#89ddff`, `lilac` `#d4bff0`.

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

Personal web pages, slide decks, dashboards, diagrams and anything shown on screen that represents the user personally. Use Voltaic Light for print.
