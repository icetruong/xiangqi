// ──────────────────────────────────────────────
//  svg-grid.js — SVG board grid renderer
//  Depends on: constants.js (VB_W, VB_H, ix, iy …)
// ──────────────────────────────────────────────

function createBoardSVG() {
    var svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('class', 'board-svg');
    svg.setAttribute('viewBox', '0 0 ' + VB_W + ' ' + VB_H);
    svg.setAttribute('preserveAspectRatio', 'xMidYMid meet');

    var color = '#b06a2a';
    var bdrInset = 14;

    // ── Helpers ──
    function addLine(x1, y1, x2, y2, sw) {
        var l = document.createElementNS(SVG_NS, 'line');
        l.setAttribute('x1', x1); l.setAttribute('y1', y1);
        l.setAttribute('x2', x2); l.setAttribute('y2', y2);
        l.setAttribute('stroke', color);
        l.setAttribute('stroke-width', sw);
        l.setAttribute('stroke-linecap', 'square');
        svg.appendChild(l);
    }
    function addRect(x, y, w, h, sw) {
        var r = document.createElementNS(SVG_NS, 'rect');
        r.setAttribute('x', x); r.setAttribute('y', y);
        r.setAttribute('width', w); r.setAttribute('height', h);
        r.setAttribute('fill', 'none');
        r.setAttribute('stroke', color);
        r.setAttribute('stroke-width', sw);
        svg.appendChild(r);
    }

    // ═══ 1. Double border ═══
    addRect(ix(0) - bdrInset, iy(0) - bdrInset,
        GRID_W + 2 * bdrInset, GRID_H + 2 * bdrInset, 4.0);
    addRect(ix(0), iy(0), GRID_W, GRID_H, 2.5);

    // ═══ 2. Horizontal lines (10 rows) ═══
    for (var r = 0; r < ROWS; r++) {
        addLine(ix(0), iy(r), ix(COLS - 1), iy(r), 2.2);
    }

    // ═══ 3. Vertical lines — river gap ═══
    for (var c = 0; c < COLS; c++) {
        if (c === 0 || c === COLS - 1) {
            addLine(ix(c), iy(0), ix(c), iy(9), 2.2);
        } else {
            addLine(ix(c), iy(0), ix(c), iy(4), 2.2);
            addLine(ix(c), iy(5), ix(c), iy(9), 2.2);
        }
    }

    // ═══ 4. Palace diagonals ═══
    addLine(ix(3), iy(0), ix(5), iy(2), 2.2);
    addLine(ix(5), iy(0), ix(3), iy(2), 2.2);
    addLine(ix(3), iy(7), ix(5), iy(9), 2.2);
    addLine(ix(5), iy(7), ix(3), iy(9), 2.2);

    // ═══ 5. Corner markers ═══
    var cannons = [[1, 2], [7, 2], [1, 7], [7, 7]];
    var pawns = [[0, 3], [2, 3], [4, 3], [6, 3], [8, 3],
    [0, 6], [2, 6], [4, 6], [6, 6], [8, 6]];
    drawCornerMarks(svg, cannons.concat(pawns), color, 1.8);

    // ═══ 6. River text ═══
    var riverY = (iy(4) + iy(5)) / 2;
    addCenteredText(svg, '楚  河', ix(2), riverY, 56, color, 0.85,
        "'Ma Shan Zheng','KaiTi','STKaiti',serif");
    addCenteredText(svg, '漢  界', ix(6), riverY, 56, color, 0.85,
        "'Ma Shan Zheng','KaiTi','STKaiti',serif");
    // Watermark
    addCenteredText(svg, 'Xiangqi.com', VB_W / 2, riverY, 20, color, 0.5,
        "'Noto Sans SC',sans-serif");

    // ═══ 7. Coordinates ═══
    for (var i = 0; i < 9; i++) {
        addCenteredText(svg, String(i + 1), ix(i), iy(0) - 35, 24, color, 0.65,
            "'Noto Sans SC',sans-serif");
        addCenteredText(svg, String(9 - i), ix(i), iy(9) + 50, 24, color, 0.65,
            "'Noto Sans SC',sans-serif");
    }

    return svg;
}

// ── Centred text helper ──
function addCenteredText(svg, text, x, y, size, fill, opacity, fontFamily) {
    var t = document.createElementNS(SVG_NS, 'text');
    t.setAttribute('x', x);
    t.setAttribute('y', y);
    t.setAttribute('font-family', fontFamily);
    t.setAttribute('font-size', size);
    t.setAttribute('fill', fill);
    t.setAttribute('opacity', opacity);
    t.setAttribute('text-anchor', 'middle');
    t.setAttribute('dominant-baseline', 'central');
    t.textContent = text;
    svg.appendChild(t);
}

// ── L-shaped corner marks ──
function drawCornerMarks(svg, positions, color, sw) {
    var gap = 8, len = 16;
    var dirs = [[-1, -1], [1, -1], [-1, 1], [1, 1]];

    for (var p = 0; p < positions.length; p++) {
        var col = positions[p][0], row = positions[p][1];
        var cx = ix(col), cy = iy(row);

        for (var d = 0; d < dirs.length; d++) {
            var dx = dirs[d][0], dy = dirs[d][1];
            if (col + dx < 0 || col + dx >= COLS) continue;

            // Horizontal arm
            var h = document.createElementNS(SVG_NS, 'line');
            h.setAttribute('x1', cx + dx * gap);
            h.setAttribute('y1', cy + dy * gap);
            h.setAttribute('x2', cx + dx * (gap + len));
            h.setAttribute('y2', cy + dy * gap);
            h.setAttribute('stroke', color);
            h.setAttribute('stroke-width', sw);
            svg.appendChild(h);

            // Vertical arm
            var v = document.createElementNS(SVG_NS, 'line');
            v.setAttribute('x1', cx + dx * gap);
            v.setAttribute('y1', cy + dy * gap);
            v.setAttribute('x2', cx + dx * gap);
            v.setAttribute('y2', cy + dy * (gap + len));
            v.setAttribute('stroke', color);
            v.setAttribute('stroke-width', sw);
            svg.appendChild(v);
        }
    }
}
