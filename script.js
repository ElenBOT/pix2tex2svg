// ─────────────────────────────────────────────────────────────────────────────
// pix2tex2svg — main script
// Forked from latex2svg; adds OCR (paste / upload) and drag-to-reorder.
// ─────────────────────────────────────────────────────────────────────────────

const API_BASE = '';

document.addEventListener('DOMContentLoaded', () => {
    const rowsContainer        = document.getElementById('rows-container');
    const addRowBtn            = document.getElementById('add-row-btn');
    const template             = document.getElementById('row-template');
    const globalFileInput      = document.getElementById('global-file-input');
    const serverDot            = document.getElementById('server-dot');
    const serverStatusLabel    = document.getElementById('server-status-label');

    const exportSizeInput           = document.getElementById('export-size');
    const exportColorInput          = document.getElementById('export-color');
    const exportBgColorInput        = document.getElementById('export-bg-color');
    const exportBgTransparentBtn    = document.getElementById('export-bg-transparent-btn');

    // Background transparent toggle
    let bgTransparent = true;
    exportBgTransparentBtn.addEventListener('click', () => {
        bgTransparent = !bgTransparent;
        exportBgTransparentBtn.classList.toggle('active', bgTransparent);
        exportBgColorInput.disabled = bgTransparent;
    });

    // ── Server health check ──────────────────────────────────────────────────
    let serverOnline = false;

    async function checkServer() {
        try {
            const res = await fetch(`${API_BASE}/health`, { signal: AbortSignal.timeout(2000) });
            serverOnline = res.ok;
        } catch {
            serverOnline = false;
        }
        serverDot.className = 'server-dot ' + (serverOnline ? 'online' : 'offline');
        serverStatusLabel.textContent = serverOnline ? 'OCR server online' : 'OCR server offline';
    }

    checkServer();
    setInterval(checkServer, 8000);

    // ── Default equations ────────────────────────────────────────────────────
    const eq1 = "x=\\sin\\left(\\frac{\\pi}{6}\\right)";
    const eq2 = "\\langle a^{\\dagger n}a^m \\rangle\n=\n\\langle\\psi|a^{\\dagger n}a^m |\\psi\\rangle";
    const eq3 = "\\rho=\\begin{pmatrix}\nP_0 & c_{01}^* \\\\\nc_{01} & P_1 \n\\end{pmatrix}";

    // Wait for MathJax before adding initial rows
    const waitForMathJax = setInterval(() => {
        if (window.MathJax && window.MathJax.tex2svgPromise) {
            clearInterval(waitForMathJax);
            addRow(eq1);
            addRow(eq2);
            addRow(eq3);
        }
    }, 100);

    addRowBtn.addEventListener('click', () => addRow(''));

    // ── Toast ────────────────────────────────────────────────────────────────
    const toast = document.getElementById('toast');
    let toastTimer;
    function showToast(msg, isError = false) {
        clearTimeout(toastTimer);
        toast.textContent = msg;
        toast.className = 'toast show' + (isError ? ' error' : '');
        toastTimer = setTimeout(() => {
            toast.classList.remove('show');
        }, 3000);
    }

    // ── Drag-and-drop row reordering ─────────────────────────────────────────
    let dragSrc = null;

    function setupDragHandle(rowEl, handleBtn) {
        handleBtn.addEventListener('mousedown', () => {
            rowEl.setAttribute('draggable', 'true');
        });
        handleBtn.addEventListener('mouseup', () => {
            rowEl.setAttribute('draggable', 'false');
        });

        rowEl.addEventListener('dragstart', (e) => {
            dragSrc = rowEl;
            rowEl.classList.add('dragging');
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', ''); // Firefox needs this
        });

        rowEl.addEventListener('dragend', () => {
            rowEl.classList.remove('dragging');
            rowEl.setAttribute('draggable', 'false');
            document.querySelectorAll('.equation-row').forEach(r => r.classList.remove('drag-over'));
        });

        rowEl.addEventListener('dragover', (e) => {
            e.preventDefault();
            e.dataTransfer.dropEffect = 'move';
            if (dragSrc && dragSrc !== rowEl) {
                document.querySelectorAll('.equation-row').forEach(r => r.classList.remove('drag-over'));
                rowEl.classList.add('drag-over');
            }
        });

        rowEl.addEventListener('dragleave', () => {
            rowEl.classList.remove('drag-over');
        });

        rowEl.addEventListener('drop', (e) => {
            e.stopPropagation();
            rowEl.classList.remove('drag-over');
            if (!dragSrc || dragSrc === rowEl) return;

            // Insert dragSrc before or after rowEl depending on mouse position
            const rect = rowEl.getBoundingClientRect();
            const midY = rect.top + rect.height / 2;
            if (e.clientY < midY) {
                rowsContainer.insertBefore(dragSrc, rowEl);
            } else {
                rowsContainer.insertBefore(dragSrc, rowEl.nextSibling);
            }
            dragSrc = null;
        });
    }

    // ── OCR helper ───────────────────────────────────────────────────────────
    async function runOcrOnFile(file, input, ocrStatus, btn) {
        if (!serverOnline) {
            showToast('OCR server is offline — start server.py first', true);
            return;
        }
        ocrStatus.textContent = 'Running OCR…';
        btn.classList.add('ocr-loading');

        try {
            const formData = new FormData();
            formData.append('file', file);
            const res = await fetch(`${API_BASE}/ocr/upload`, { method: 'POST', body: formData });
            if (!res.ok) throw new Error(`Server error ${res.status}`);
            const data = await res.json();
            input.value = data.latex;
            input.dispatchEvent(new Event('input'));
            ocrStatus.textContent = 'OCR complete ✓';
            setTimeout(() => { ocrStatus.textContent = ''; }, 3000);
            showToast('LaTeX extracted from image!');
        } catch (err) {
            ocrStatus.textContent = '';
            showToast('OCR failed: ' + err.message, true);
        } finally {
            btn.classList.remove('ocr-loading');
        }
    }

    async function runOcrOnBase64(b64, input, ocrStatus, btn) {
        if (!serverOnline) {
            showToast('OCR server is offline — start server.py first', true);
            return;
        }
        ocrStatus.textContent = 'Running OCR…';
        btn.classList.add('ocr-loading');

        try {
            const res = await fetch(`${API_BASE}/ocr/base64`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ image: b64 })
            });
            if (!res.ok) throw new Error(`Server error ${res.status}`);
            const data = await res.json();
            input.value = data.latex;
            input.dispatchEvent(new Event('input'));
            ocrStatus.textContent = 'OCR complete ✓';
            setTimeout(() => { ocrStatus.textContent = ''; }, 3000);
            showToast('LaTeX extracted from clipboard image!');
        } catch (err) {
            ocrStatus.textContent = '';
            showToast('OCR failed: ' + err.message, true);
        } finally {
            btn.classList.remove('ocr-loading');
        }
    }

    // Convert a clipboard ImageBitmap → canvas → base64
    function bitmapToBase64(bitmap) {
        const canvas = document.createElement('canvas');
        canvas.width  = bitmap.width;
        canvas.height = bitmap.height;
        canvas.getContext('2d').drawImage(bitmap, 0, 0);
        return canvas.toDataURL('image/png'); // data-URI
    }

    // ── addRow ───────────────────────────────────────────────────────────────
    function addRow(initialLatex) {
        const rowFrag = template.content.cloneNode(true);
        const rowEl   = rowFrag.querySelector('.equation-row');

        const input      = rowEl.querySelector('.latex-input');
        const ocrStatus  = rowEl.querySelector('.ocr-status');
        const svgContainer = rowEl.querySelector('.svg-output');
        const errorMsg   = rowEl.querySelector('.error-msg');
        const removeBtn  = rowEl.querySelector('.remove-row-btn');

        // Left buttons
        const dragHandleBtn  = rowEl.querySelector('.drag-handle-btn');
        const ocrPasteBtn    = rowEl.querySelector('.ocr-paste-btn');
        const ocrUploadBtn   = rowEl.querySelector('.ocr-upload-btn');

        // Right buttons
        const copySvgBtn              = rowEl.querySelector('.copy-svg-btn');
        const copyPngBtn              = rowEl.querySelector('.copy-png-btn');
        const copyDropdownContainer   = rowEl.querySelector('.copy-dropdown-container');
        const copyBtn                 = rowEl.querySelector('.copy-btn');
        const downloadDropdownContainer = rowEl.querySelector('.download-dropdown-container');
        const downloadBtn             = rowEl.querySelector('.download-btn');
        const downloadSvgBtn          = rowEl.querySelector('.download-svg-btn');
        const downloadPngBtn          = rowEl.querySelector('.download-png-btn');
        const downloadPdfBtn          = rowEl.querySelector('.download-pdf-btn');

        input.value = initialLatex;

        if (initialLatex) {
            renderMath(initialLatex, svgContainer, errorMsg);
        }

        // Debounced live preview
        let debounceTimer = null;
        input.addEventListener('input', () => {
            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(() => {
                renderMath(input.value, svgContainer, errorMsg);
            }, 300);
        });

        // Remove
        removeBtn.addEventListener('click', () => rowEl.remove());

        // Drag-to-reorder
        setupDragHandle(rowEl, dragHandleBtn);

        // ── OCR: paste from clipboard (Button) ───────────────────────────────
        ocrPasteBtn.addEventListener('click', async () => {
            try {
                if (!navigator.clipboard || !navigator.clipboard.read) {
                    showToast('Button paste requires HTTPS or localhost. Try pressing Ctrl+V inside the text box instead!', true);
                    return;
                }
                const items = await navigator.clipboard.read();
                let found = false;
                for (const item of items) {
                    const imageType = item.types.find(t => t.startsWith('image/'));
                    if (imageType) {
                        const blob = await item.getType(imageType);
                        const bitmap = await createImageBitmap(blob);
                        const b64 = bitmapToBase64(bitmap);
                        await runOcrOnBase64(b64, input, ocrStatus, ocrPasteBtn);
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    showToast('No image found in clipboard', true);
                }
            } catch (err) {
                showToast('Clipboard read denied: ' + err.message, true);
            }
        });

        // ── OCR: paste from clipboard (Ctrl+V / Native Paste) ───────────────
        // This works even on HTTP LAN connections where navigator.clipboard is blocked!
        input.addEventListener('paste', async (e) => {
            const items = (e.clipboardData || window.clipboardData).items;
            for (const item of items) {
                if (item.type.indexOf('image/') === 0) {
                    e.preventDefault(); // Stop default text paste
                    const blob = item.getAsFile();
                    await runOcrOnFile(blob, input, ocrStatus, ocrPasteBtn);
                    break;
                }
            }
        });

        // ── OCR: upload file ─────────────────────────────────────────────────
        ocrUploadBtn.addEventListener('click', () => {
            // Re-use the single hidden file input; attach a one-shot handler
            const handler = async (e) => {
                globalFileInput.removeEventListener('change', handler);
                const file = e.target.files[0];
                globalFileInput.value = ''; // reset so same file can be re-selected
                if (!file) return;
                await runOcrOnFile(file, input, ocrStatus, ocrUploadBtn);
            };
            globalFileInput.addEventListener('change', handler);
            globalFileInput.click();
        });

        // ── Copy dropdown ────────────────────────────────────────────────────
        copyBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            document.querySelectorAll('.copy-dropdown-container.active, .download-dropdown-container.active')
                .forEach(el => { if (el !== copyDropdownContainer) el.classList.remove('active'); });
            copyDropdownContainer.classList.toggle('active');
        });

        // ── Download dropdown ────────────────────────────────────────────────
        downloadBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            document.querySelectorAll('.download-dropdown-container.active')
                .forEach(el => { if (el !== downloadDropdownContainer) el.classList.remove('active'); });
            downloadDropdownContainer.classList.toggle('active');
        });

        copySvgBtn.addEventListener('click', () => {
            handleCopySvg(svgContainer, copyBtn);
            copyDropdownContainer.classList.remove('active');
        });
        copyPngBtn.addEventListener('click', () => {
            handleCopyPng(svgContainer, copyBtn);
            copyDropdownContainer.classList.remove('active');
        });
        downloadSvgBtn.addEventListener('click', () => {
            handleDownloadSvg(svgContainer);
            downloadDropdownContainer.classList.remove('active');
        });
        downloadPngBtn.addEventListener('click', () => {
            handleDownloadImage(svgContainer);
            downloadDropdownContainer.classList.remove('active');
        });
        downloadPdfBtn.addEventListener('click', () => {
            handleDownloadPdf(svgContainer);
            downloadDropdownContainer.classList.remove('active');
        });

        rowsContainer.appendChild(rowFrag);
    }

    // Close dropdowns on outside click
    document.addEventListener('click', () => {
        document.querySelectorAll('.download-dropdown-container.active, .copy-dropdown-container.active')
            .forEach(el => el.classList.remove('active'));
    });

    // ── MathJax rendering ────────────────────────────────────────────────────
    function renderMath(latex, container, errorMsg) {
        if (!latex.trim()) {
            container.innerHTML = '';
            errorMsg.style.display = 'none';
            return;
        }

        MathJax.tex2svgPromise(latex, { display: true }).then((node) => {
            container.innerHTML = '';
            container.appendChild(node);
            const svg = container.querySelector('svg');
            if (svg) {
                svg.style.width  = 'auto';
                svg.style.height = 'auto';
            }
            errorMsg.style.display = 'none';
        }).catch((err) => {
            errorMsg.textContent = err.message;
            errorMsg.style.display = 'block';
        });
    }

    // ── Export helpers (unchanged from latex2svg) ────────────────────────────

    function getSvgString(container) {
        const svg = container.querySelector('svg');
        if (!svg) return null;

        const clone = svg.cloneNode(true);
        const exportColor = exportColorInput.value;
        const exportSize  = parseInt(exportSizeInput.value) || 32;

        // Measure dimensions
        const tempDiv = document.createElement('div');
        tempDiv.style.fontSize = `${exportSize}px`;
        tempDiv.appendChild(clone.cloneNode(true));
        document.body.appendChild(tempDiv);
        const tempSvg = tempDiv.querySelector('svg');
        const rect    = tempSvg.getBoundingClientRect();
        document.body.removeChild(tempDiv);

        clone.setAttribute('width',  `${rect.width.toFixed(3)}`);
        clone.setAttribute('height', `${rect.height.toFixed(3)}`);

        clone.removeAttribute('focusable');
        clone.removeAttribute('role');
        clone.removeAttribute('aria-hidden');
        clone.removeAttribute('style');

        const mathG = clone.querySelector('g[data-mml-node="math"]');
        if (mathG) {
            const input = container.closest('.equation-row').querySelector('.latex-input');
            if (input) mathG.setAttribute('data-latex', input.value);
        }

        clone.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
        clone.setAttribute('xmlns:xlink', 'http://www.w3.org/1999/xlink');

        const serializer = new XMLSerializer();
        let svgString = serializer.serializeToString(clone);

        svgString = svgString.replace(/currentColor/g, exportColor);

        if (!bgTransparent) {
            const bg = exportBgColorInput.value;
            const vbMatch = clone.getAttribute('viewBox');
            let rectAttrs;
            if (vbMatch) {
                const [vx, vy, vw, vh] = vbMatch.trim().split(/[\s,]+/).map(Number);
                rectAttrs = `x="${vx}" y="${vy}" width="${vw}" height="${vh}"`;
            } else {
                rectAttrs = `width="100%" height="100%"`;
            }
            svgString = svgString.replace(/(<svg[^>]*>)/, `$1<rect ${rectAttrs} fill="${bg}"/>`);
        }

        svgString = svgString.replace(/d=""/g, 'd="M 0 0"');

        return '<?xml version="1.0" encoding="UTF-8" standalone="no" ?>\n' + svgString;
    }

    async function handleCopySvg(container, btn) {
        const svgString = getSvgString(container);
        if (!svgString) return;

        try {
            if (window.ClipboardItem) {
                const svgBlob = new Blob([svgString], { type: 'image/svg+xml' });
                await navigator.clipboard.write([new ClipboardItem({ 'image/svg+xml': svgBlob })]);
            } else {
                await navigator.clipboard.writeText(svgString);
            }
            flashSuccess(btn);
            showToast('SVG copied!');
        } catch (err) {
            try {
                await navigator.clipboard.writeText(svgString);
                flashSuccess(btn);
                showToast('SVG copied as text!');
            } catch {
                showToast('Failed to copy SVG', true);
            }
        }
    }

    async function handleCopyPng(container, btn) {
        createSvgCanvas(container, async (canvas) => {
            try {
                canvas.toBlob(async (blob) => {
                    await navigator.clipboard.write([new ClipboardItem({ 'image/png': blob })]);
                    flashSuccess(btn);
                    showToast('PNG copied!');
                }, 'image/png');
            } catch (err) {
                showToast('Failed to copy PNG: ' + err.message, true);
            }
        });
    }

    function flashSuccess(btn) {
        const orig = btn.innerHTML;
        btn.innerHTML = '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="green" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>';
        setTimeout(() => { btn.innerHTML = orig; }, 2000);
    }

    function handleDownloadSvg(container) {
        const svgString = getSvgString(container);
        if (!svgString) return;
        const blob = new Blob([svgString], { type: 'image/svg+xml;charset=utf-8' });
        triggerDownload(URL.createObjectURL(blob), 'expression.svg');
    }

    function createSvgCanvas(container, callback) {
        const svgString = getSvgString(container);
        if (!svgString) return;

        const parser    = new DOMParser();
        const svgDoc    = parser.parseFromString(svgString, 'image/svg+xml');
        const parsedSvg = svgDoc.querySelector('svg');
        const svgWidth  = parseFloat(parsedSvg.getAttribute('width'));
        const svgHeight = parseFloat(parsedSvg.getAttribute('height'));

        const img     = new Image();
        const svgBlob = new Blob([svgString], { type: 'image/svg+xml;charset=utf-8' });
        const url     = URL.createObjectURL(svgBlob);

        img.onload = () => {
            const canvas  = document.createElement('canvas');
            const ctx     = canvas.getContext('2d');
            const scale   = 2; // 4× pixel density
            canvas.width  = svgWidth  * scale;
            canvas.height = svgHeight * scale;
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
            URL.revokeObjectURL(url);
            callback(canvas);
        };
        img.src = url;
    }

    function handleDownloadImage(container) {
        createSvgCanvas(container, (canvas) => {
            triggerDownload(canvas.toDataURL('image/png'), 'expression.png');
        });
    }

    async function handleDownloadPdf(container) {
        const svgString = getSvgString(container);
        if (!svgString) return;

        const tempDiv = document.createElement('div');
        tempDiv.style.cssText = 'position:absolute;left:-9999px';
        tempDiv.innerHTML = svgString;
        document.body.appendChild(tempDiv);

        const svgElement = tempDiv.querySelector('svg');
        const width      = parseFloat(svgElement.getAttribute('width'));
        const height     = parseFloat(svgElement.getAttribute('height'));
        const padding    = 20;
        const { jsPDF }  = window.jspdf;
        const pdf        = new jsPDF('l', 'pt', [width + padding * 2, height + padding * 2]);

        try {
            await pdf.svg(svgElement, { x: padding, y: padding, width, height });
            pdf.save('expression.pdf');
        } catch (err) {
            showToast('Failed to generate PDF: ' + err.message, true);
        } finally {
            document.body.removeChild(tempDiv);
        }
    }

    function triggerDownload(url, filename) {
        const a = document.createElement('a');
        a.href     = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
    }
});
