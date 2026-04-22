# latex2svg

A browser-based tool for converting LaTeX math expressions into high-quality SVG.
No installation. No server. Just open and use.

https://elenbot.github.io/latex2svg/

## What it does

- Renders LaTeX using **MathJax v4** with NCM fonts
- Copy as **SVG** (paste directly into Adobe Illustrator or Microsoft PowerPoint)
- Copy as **PNG** (paste into Discord, Messenger, or any chat app)
- Download as SVG / PNG / PDF
- Set export size, expression color, and background color per session

## Tech

- **Renderer**: MathJax v4 (`tex-svg`)
- **PDF export**: jsPDF + svg2pdf.js
- **UI font**: Inter (Google Fonts)
- **LaTeX fonts**: New Computer Modern (via MathJax)
- No build step — pure HTML / CSS / JS

## License

MIT
