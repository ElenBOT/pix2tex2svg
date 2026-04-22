document.addEventListener('DOMContentLoaded', () => {
    const rowsContainer = document.getElementById('rows-container');
    const addRowBtn = document.getElementById('add-row-btn');
    const template = document.getElementById('row-template');
    
    const globalSizeInput = document.getElementById('global-size');
    const sizeValueDisplay = document.getElementById('size-value');
    const globalColorInput = document.getElementById('global-color');

    // Default equation
    const defaultEquation = "E = mc^2";

    // Wait for MathJax to be ready before adding the first row
    const waitForMathJax = setInterval(() => {
        if (window.MathJax && window.MathJax.tex2svgPromise) {
            clearInterval(waitForMathJax);
            addRow(defaultEquation);
        }
    }, 100);

    // Global style handlers
    globalSizeInput.addEventListener('input', (e) => {
        const size = e.target.value;
        sizeValueDisplay.textContent = `${size}px`;
        document.documentElement.style.setProperty('--formula-size', `${size}px`);
    });

    globalColorInput.addEventListener('input', (e) => {
        const color = e.target.value;
        document.documentElement.style.setProperty('--formula-color', color);
    });

    // Add new row handler
    addRowBtn.addEventListener('click', () => {
        addRow("");
    });

    function addRow(initialLatex) {
        const rowFrag = template.content.cloneNode(true);
        const rowEl = rowFrag.querySelector('.equation-row');
        
        const input = rowEl.querySelector('.latex-input');
        const svgContainer = rowEl.querySelector('.svg-output');
        const errorMsg = rowEl.querySelector('.error-msg');
        const removeBtn = rowEl.querySelector('.remove-row-btn');
        
        const copySvgBtn = rowEl.querySelector('.copy-svg-btn');
        const downloadSvgBtn = rowEl.querySelector('.download-svg-btn');
        const downloadPngBtn = rowEl.querySelector('.download-png-btn');
        const downloadPdfBtn = rowEl.querySelector('.download-pdf-btn');

        input.value = initialLatex;

        // Render initially
        if (initialLatex) {
            renderMath(initialLatex, svgContainer, errorMsg);
        }

        // Debounce input to avoid excessive rendering
        let timeout = null;
        input.addEventListener('input', () => {
            clearTimeout(timeout);
            timeout = setTimeout(() => {
                renderMath(input.value, svgContainer, errorMsg);
            }, 300); // 300ms delay
        });

        // Remove row
        removeBtn.addEventListener('click', () => {
            rowEl.remove();
        });

        // Action Buttons
        copySvgBtn.addEventListener('click', () => handleCopySvg(svgContainer, copySvgBtn));
        downloadSvgBtn.addEventListener('click', () => handleDownloadSvg(svgContainer));
        downloadPngBtn.addEventListener('click', () => handleDownloadImage(svgContainer, 'png'));
        downloadPdfBtn.addEventListener('click', () => handleDownloadPdf(svgContainer));

        rowsContainer.appendChild(rowFrag);
    }

    function renderMath(latex, container, errorMsg) {
        if (!latex.trim()) {
            container.innerHTML = '';
            errorMsg.style.display = 'none';
            return;
        }

        // Use MathJax v3 Promise API
        MathJax.tex2svgPromise(latex, {display: true}).then((node) => {
            container.innerHTML = '';
            // Node is a mjx-container element, we append it
            container.appendChild(node);
            
            // Fix SVG sizing issues and MathJax internal styles
            const svg = container.querySelector('svg');
            if (svg) {
                // Ensure SVG scales cleanly
                svg.style.width = 'auto';
                svg.style.height = 'auto';
            }

            errorMsg.style.display = 'none';
        }).catch((err) => {
            errorMsg.textContent = err.message;
            errorMsg.style.display = 'block';
        });
    }

    // --- Export Helpers --- //

    // Gets a serialized, self-contained SVG string
    function getSvgString(container) {
        const svg = container.querySelector('svg');
        if (!svg) return null;

        // Clone so we don't modify the DOM one
        const clone = svg.cloneNode(true);
        
        // Apply current color explicitly for export
        const color = getComputedStyle(document.documentElement).getPropertyValue('--formula-color').trim();
        clone.setAttribute('fill', color);
        clone.style.color = color;
        clone.style.fill = color;
        clone.removeAttribute('focusable');
        
        const serializer = new XMLSerializer();
        let svgString = serializer.serializeToString(clone);
        
        // Add XML namespace if missing
        if (!svgString.match(/^<svg[^>]+xmlns="http\:\/\/www\.w3\.org\/2000\/svg"/)) {
            svgString = svgString.replace(/^<svg/, '<svg xmlns="http://www.w3.org/2000/svg"');
        }
        
        return svgString;
    }

    async function handleCopySvg(container, btn) {
        const svgString = getSvgString(container);
        if (!svgString) return;

        try {
            await navigator.clipboard.writeText(svgString);
            const originalText = btn.textContent;
            btn.textContent = "Copied!";
            setTimeout(() => { btn.textContent = originalText; }, 2000);
        } catch (err) {
            console.error('Failed to copy', err);
            alert('Failed to copy SVG to clipboard.');
        }
    }

    function handleDownloadSvg(container) {
        const svgString = getSvgString(container);
        if (!svgString) return;

        const blob = new Blob([svgString], {type: "image/svg+xml;charset=utf-8"});
        const url = URL.createObjectURL(blob);
        triggerDownload(url, 'formula.svg');
    }

    function createSvgCanvas(container, callback) {
        const svgString = getSvgString(container);
        if (!svgString) return;

        const svg = container.querySelector('svg');
        // Get natural dimensions from the ex/em width and current font size
        const fontSize = parseInt(getComputedStyle(document.documentElement).getPropertyValue('--formula-size')) || 32;
        
        // To get accurate pixels, we can draw the SVG on a canvas
        const img = new Image();
        const svgBlob = new Blob([svgString], {type: "image/svg+xml;charset=utf-8"});
        const url = URL.createObjectURL(svgBlob);

        img.onload = () => {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');

            // MathJax width/height are usually in ex or em, convert to pixels via getBoundingClientRect
            const rect = svg.getBoundingClientRect();
            
            // Add some padding
            const padding = 20;
            canvas.width = rect.width + padding * 2;
            canvas.height = rect.height + padding * 2;

            // Draw transparent background
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            
            ctx.drawImage(img, padding, padding, rect.width, rect.height);
            URL.revokeObjectURL(url);
            
            callback(canvas);
        };
        img.src = url;
    }

    function handleDownloadImage(container) {
        createSvgCanvas(container, (canvas) => {
            const imgURL = canvas.toDataURL("image/png");
            triggerDownload(imgURL, 'formula.png');
        });
    }

    function handleDownloadPdf(container) {
        createSvgCanvas(container, (canvas) => {
            const imgData = canvas.toDataURL("image/png");
            
            // Default jspdf dimensions are mm, A4 size
            const { jsPDF } = window.jspdf;
            const pdf = new jsPDF('l', 'mm', [canvas.width * 0.264583, canvas.height * 0.264583]); // px to mm approx
            
            pdf.addImage(imgData, 'PNG', 0, 0, canvas.width * 0.264583, canvas.height * 0.264583);
            pdf.save('formula.pdf');
        });
    }

    function triggerDownload(url, filename) {
        const link = document.createElement('a');
        link.href = url;
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    }
});
