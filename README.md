# latex2svg

A lightweight web tool that converts LaTeX math expressions to high‑quality SVG files.

## Features
- **Instant SVG output** using MathJax v4 for crisp NCM fonts.
- **Copy‑paste ready** – generated SVGs can be directly pasted into **Adobe Illustrator**, **Microsoft PowerPoint**, or any vector‑aware editor.
- Supports custom LaTeX fonts (e.g., `STIX`, `Latin Modern`).
- No server side required – runs entirely in the browser.

## Quick Start
1. Open `https://elenbot.github.io/latex2svg/` in a browser.
2. Type your LaTeX expression in the input area.
3. Click **Export SVG**. The SVG code is copied to the clipboard.
4. Paste the SVG into Illustrator, PowerPoint, or any other vector tool.

## Dependencies
- **MathJax v4** – renders LaTeX to SVG.
- **svg2pdf.js** (optional) – can also export PDF if needed.
- Built‑in **font loader** pulls fonts from Google Fonts; you can configure the `fontFamily` in `script.js`.

## Development
```bash
# Install dependencies (if any)
npm install
# Run a local dev server
npm run dev
```

## License
MIT – see `LICENSE` for details.
