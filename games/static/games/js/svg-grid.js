// ──────────────────────────────────────────────
//  svg-grid.js — Normalized viewBox="0 0 8 9"
//  Grid fills edge-to-edge; no internal margins.
//  Depends on: constants.js
// ──────────────────────────────────────────────

function createBoardSVG() {
    var svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('class', 'board-svg');
    // Normalized: col 0..8, row 0..9
    svg.setAttribute('viewBox', '0 0 8 9');
    svg.setAttribute('preserveAspectRatio', 'none');  // fill exactly

    var c = '#b06a2a';   // warm orange-brown

    function line(x1, y1, x2, y2, sw, color) {
        var l = document.createElementNS(SVG_NS, 'line');
        l.setAttribute('x1', x1); l.setAttribute('y1', y1);
        l.setAttribute('x2', x2); l.setAttribute('y2', y2);
        l.setAttribute('stroke', color || c);
        l.setAttribute('stroke-width', sw);
        l.setAttribute('stroke-linecap', 'square');
        svg.appendChild(l); return l;
    }


    function rect(x, y, w, h, sw) {
        var r = document.createElementNS(SVG_NS, 'rect');
        r.setAttribute('x', x); r.setAttribute('y', y);
        r.setAttribute('width', w); r.setAttribute('height', h);
        r.setAttribute('fill', 'none');
        r.setAttribute('stroke', c);
        r.setAttribute('stroke-width', sw);
        svg.appendChild(r);
    }
    function txt(text, x, y, size, opacity, font) {
        var t = document.createElementNS(SVG_NS, 'text');
        t.setAttribute('x', x); t.setAttribute('y', y);
        t.setAttribute('font-size', size);
        t.setAttribute('font-family', font || "'Ma Shan Zheng','KaiTi',serif");
        t.setAttribute('fill', c); t.setAttribute('opacity', opacity);
        t.setAttribute('text-anchor', 'middle');
        t.setAttribute('dominant-baseline', 'central');
        t.textContent = text; svg.appendChild(t);
    }

    // ── 1. Outer border (full grid, 0,0 to 8,9)
    rect(0, 0, 8, 9, 0.08);

    // ── 2. Horizontal lines (10 rows: y=0..9)
    for (var r = 0; r <= 9; r++) line(0, r, 8, r, 0.04);

    // ── 3. Vertical lines with river gap (y=4..5)
    for (var col = 0; col <= 8; col++) {
        if (col === 0 || col === 8) {
            line(col, 0, col, 9, 0.04);
        } else {
            line(col, 0, col, 4, 0.04);
            line(col, 5, col, 9, 0.04);
        }
    }

    // ── 4. Palace diagonals
    line(3, 0, 5, 2, 0.04);
    line(5, 0, 3, 2, 0.04);
    line(3, 7, 5, 9, 0.04);
    line(5, 7, 3, 9, 0.04);

    // ── 5. Corner markers (cannon + pawn positions)
    var markers = [
        [1, 2], [7, 2], [1, 7], [7, 7],
        [0, 3], [2, 3], [4, 3], [6, 3], [8, 3],
        [0, 6], [2, 6], [4, 6], [6, 6], [8, 6]
    ];
    markers.forEach(function (m) {
        drawMark(svg, m[0], m[1], c);
    });

    // ── 6. River text
    var midY = 4.5;
    txt('楚  河', 2, midY, 0.55, 0.85);
    txt('漢  界', 6, midY, 0.55, 0.85);
    txt('Xiangqi.com', 4, midY, 0.18, 0.45, "'Noto Sans SC',sans-serif");

    // ── 7. Coordinate numbers (1-9 top, 9-1 bottom)
    for (var i = 0; i <= 8; i++) {
        txt(String(i + 1), i, -0.4, 0.22, 0.65, "'Noto Sans SC',sans-serif");
        txt(String(9 - i), i, 9.4, 0.22, 0.65, "'Noto Sans SC',sans-serif");
    }

    return svg;
}

// ── L-shaped corner mark (in normalized 0..8 x 0..9 space)
function drawMark(svg, col, row, color) {
    var gap = 0.12, len = 0.22, sw = 0.04;
    var dirs = [[-1, -1], [1, -1], [-1, 1], [1, 1]];
    dirs.forEach(function (d) {
        var dx = d[0], dy = d[1];
        if (col + dx < 0 || col + dx > 8) return;
        // horizontal arm
        var h = document.createElementNS(SVG_NS, 'line');
        h.setAttribute('x1', col + dx * gap); h.setAttribute('y1', row + dy * gap);
        h.setAttribute('x2', col + dx * (gap + len)); h.setAttribute('y2', row + dy * gap);
        h.setAttribute('stroke', color); h.setAttribute('stroke-width', sw);
        svg.appendChild(h);
        // vertical arm
        var v = document.createElementNS(SVG_NS, 'line');
        v.setAttribute('x1', col + dx * gap); v.setAttribute('y1', row + dy * gap);
        v.setAttribute('x2', col + dx * gap); v.setAttribute('y2', row + dy * (gap + len));
        v.setAttribute('stroke', color); v.setAttribute('stroke-width', sw);
        svg.appendChild(v);
    });
}
