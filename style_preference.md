# User UI/UX Style Preferences & Vibe Guide

This document outlines the core design preferences, aesthetic choices, and coding guidelines for this user. When assisting with web development, UI design, or frontend coding (often referred to as "vibe coding"), please adhere strictly to these principles.

## 1. Aesthetic & Vibe
- **Professional & Minimalist**: The overall feel should be clean, academic, and highly professional. Avoid anything that looks "casual," "playful," or overly flashy.
- **Color Palette**: Stick to clean, high-contrast monochrome or very subtle themes. Prefer classic black on white (e.g., `#000000` text on `#FFFFFF` backgrounds). Use subtle grays (e.g., `#f5f5f5`, `#e0e0e0`) for borders, backgrounds, and hover effects. Avoid loud, generic, or highly saturated colors unless strictly necessary for semantic alerts (like error messages).
- **No Gradients/Glassmorphism**: Avoid trendy, heavy UI effects like complex gradients, heavy box-shadows, or glassmorphism. Keep it flat and crisp.

## 2. Geometry & Shapes
- **Sharp Edges (Crucial)**: Use sharp, square corners for UI elements (inputs, buttons, containers, dropdowns). **Set `border-radius: 0;`**. Rounded corners are perceived as too casual.
- **Crisp Borders**: Use thin, solid borders to separate sections.

## 3. Layout & Density
- **Compact & Efficient**: Maximize screen real estate. Use compact layouts (like tight grids or flexbox columns) that prevent the user from having to scroll unnecessarily. 
- **Column-based Workflows**: For list-based or item-based UI (like a list of equations), prefer horizontal inline layouts (e.g., `[ Input ] | [ Preview ] | [ Action Buttons ]`) rather than stacking them vertically.

## 4. UI Elements & Interactivity
- **Icons Over Text**: For action buttons (Copy, Delete, Download, Settings), **always use clean, minimalist SVG icons** instead of text labels. Text labels clutter the UI.
- **Vertical/Compact Action Bars**: Group action icons tightly together (e.g., a vertical column of square buttons on the right side of a row).
- **Dropdowns & Menus**: If a button has multiple sub-actions (e.g., downloading in different formats: SVG/PNG/PDF), use a clean, tight dropdown menu triggered by clicking the icon, rather than spreading out multiple buttons.
- **Hover States**: Provide clear but subtle visual feedback on hover (e.g., slight background darkening, icon color change).

## 5. Code & Technical Preferences
- **Vanilla First**: Prefer standard HTML/CSS/JS without bulky frameworks or utility classes (like Tailwind) unless explicitly requested.
- **Vector & High Quality**: Always prioritize raw vector output (clean standalone SVGs, vector-based PDFs over rasterized canvases). Ensure outputs are scalable without pixelation.
- **Typography**: Use modern, clean sans-serif fonts for the UI (e.g., `Inter`, `Roboto`, `Helvetica Neue`). Ensure math or technical outputs use industry-standard fonts (e.g., New Computer Modern for LaTeX).

---
**Agent Instruction**: Before generating UI code, review this document. Ensure that the CSS you write inherently implements `border-radius: 0`, uses a monochrome/clean palette, heavily utilizes SVG icons for buttons, and structures the layout compactly.
