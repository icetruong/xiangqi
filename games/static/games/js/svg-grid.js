// ──────────────────────────────────────────────
//  svg-grid.js — SVG board grid renderer
//  Depends on: constants.js
// ──────────────────────────────────────────────

function createBoardSVG() {
    var vbW = BOARD_W + BOARD_PAD * 2;
    var vbH = BOARD_H + BOARD_PAD * 2;

    var svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('class', 'board-svg');
    svg.setAttribute('viewBox', '0 0 ' + vbW + ' ' + vbH);
    svg.setAttribute('preserveAspectRatio', 'xMidYMid meet');

    // ── Color palette ──
    var lineColor = '#8b6c42';
    var lineColorLight = '#a08050';
    var borderWidth = 2;
    var gridWidth = 1.2;
    var thinWidth = 0.9;

    // ── Helpers ──
    var ix = function (c) { return BOARD_PAD + c * CELL_SIZE; };
    var iy = function (r) { return BOARD_PAD + r * CELL_SIZE; };

    function line(x1, y1, x2, y2, color, sw) {
        var l = document.createElementNS(SVG_NS, 'line');
        l.setAttribute('x1', x1);
        l.setAttribute('y1', y1);
        l.setAttribute('x2', x2);
        l.setAttribute('y2', y2);
        l.setAttribute('stroke', color);
        l.setAttribute('stroke-width', sw);
        l.setAttribute('stroke-linecap', 'square');
        return l;
    }

    // ── 1. Outer border rectangle ──
    var border = document.createElementNS(SVG_NS, 'rect');
    border.setAttribute('x', ix(0) - 1);
    border.setAttribute('y', iy(0) - 1);
    border.setAttribute('width', BOARD_W + 2);
    border.setAttribute('height', BOARD_H + 2);
    border.setAttribute('fill', 'none');
    border.setAttribute('stroke', lineColor);
    border.setAttribute('stroke-width', borderWidth);
    svg.appendChild(border);

    // ── 2. Horizontal lines (10 rows) ──
    for (var r = 0; r < ROWS; r++) {
        svg.appendChild(line(ix(0), iy(r), ix(COLS - 1), iy(r), lineColor, gridWidth));
    }

    // ── 3. Vertical lines — inner 7 split by river ──
    for (var c = 0; c < COLS; c++) {
        if (c === 0 || c === COLS - 1) {
            svg.appendChild(line(ix(c), iy(0), ix(c), iy(ROWS - 1), lineColor, gridWidth));
        } else {
            svg.appendChild(line(ix(c), iy(0), ix(c), iy(4), lineColorLight, gridWidth));
            svg.appendChild(line(ix(c), iy(5), ix(c), iy(ROWS - 1), lineColorLight, gridWidth));
        }
    }

    // ── 4. Palace diagonals (X) ──
    drawPalace(svg, 3, 0, lineColor, thinWidth);
    drawPalace(svg, 3, 7, lineColor, thinWidth);

    // ── 5. Corner marks ──
    var cannonPos = [[1, 2], [7, 2], [1, 7], [7, 7]];
    var pawnPos = [
        [0, 3], [2, 3], [4, 3], [6, 3], [8, 3],
        [0, 6], [2, 6], [4, 6], [6, 6], [8, 6]
    ];
    var allMarks = cannonPos.concat(pawnPos);
    for (var i = 0; i < allMarks.length; i++) {
        drawCornerMarks(svg, allMarks[i][0], allMarks[i][1], lineColorLight, thinWidth);
    }

    // ── 6. River text ──
    var riverY = (iy(4) + iy(5)) / 2;
    var riverFontSize = Math.round(CELL_SIZE * 0.56);

    var textLeft = document.createElementNS(SVG_NS, 'text');
    textLeft.setAttribute('x', ix(2));
    textLeft.setAttribute('y', riverY + riverFontSize * 0.35);
    textLeft.setAttribute('font-family', "'Ma Shan Zheng', 'KaiTi', 'STKaiti', cursive");
    textLeft.setAttribute('font-size', riverFontSize);
    textLeft.setAttribute('fill', lineColor);
    textLeft.setAttribute('opacity', '0.65');
    textLeft.setAttribute('text-anchor', 'middle');
    textLeft.setAttribute('letter-spacing', String(Math.round(CELL_SIZE * 0.55)));
    textLeft.textContent = '\u695A\u6CB3';
    svg.appendChild(textLeft);

    var textRight = document.createElementNS(SVG_NS, 'text');
    textRight.setAttribute('x', ix(6));
    textRight.setAttribute('y', riverY + riverFontSize * 0.35);
    textRight.setAttribute('font-family', "'Ma Shan Zheng', 'KaiTi', 'STKaiti', cursive");
    textRight.setAttribute('font-size', riverFontSize);
    textRight.setAttribute('fill', lineColor);
    textRight.setAttribute('opacity', '0.65');
    textRight.setAttribute('text-anchor', 'middle');
    textRight.setAttribute('letter-spacing', String(Math.round(CELL_SIZE * 0.55)));
    textRight.textContent = '\u6F22\u754C';
    svg.appendChild(textRight);

    // ── 7. Coordinate numbers ──
    var coordFont = Math.round(CELL_SIZE * 0.22);
    var coordColor = lineColorLight;
    var coordOpacity = '0.7';

    for (var i = 0; i < 9; i++) {
        var txt = document.createElementNS(SVG_NS, 'text');
        txt.setAttribute('x', ix(i));
        txt.setAttribute('y', BOARD_PAD - Math.round(CELL_SIZE * 0.2));
        txt.setAttribute('font-family', "'Noto Sans SC', sans-serif");
        txt.setAttribute('font-size', coordFont);
        txt.setAttribute('fill', coordColor);
        txt.setAttribute('opacity', coordOpacity);
        txt.setAttribute('text-anchor', 'middle');
        txt.textContent = (i + 1).toString();
        svg.appendChild(txt);
    }

    for (var i = 0; i < 9; i++) {
        var txt = document.createElementNS(SVG_NS, 'text');
        txt.setAttribute('x', ix(i));
        txt.setAttribute('y', iy(ROWS - 1) + Math.round(CELL_SIZE * 0.38));
        txt.setAttribute('font-family', "'Noto Sans SC', sans-serif");
        txt.setAttribute('font-size', coordFont);
        txt.setAttribute('fill', coordColor);
        txt.setAttribute('opacity', coordOpacity);
        txt.setAttribute('text-anchor', 'middle');
        txt.textContent = (9 - i).toString();
        svg.appendChild(txt);
    }

    return svg;
}

function drawPalace(svg, startCol, startRow, color, sw) {
    var ix = function (c) { return BOARD_PAD + c * CELL_SIZE; };
    var iy = function (r) { return BOARD_PAD + r * CELL_SIZE; };

    var d1 = document.createElementNS(SVG_NS, 'line');
    d1.setAttribute('x1', ix(startCol));
    d1.setAttribute('y1', iy(startRow));
    d1.setAttribute('x2', ix(startCol + 2));
    d1.setAttribute('y2', iy(startRow + 2));
    d1.setAttribute('stroke', color);
    d1.setAttribute('stroke-width', sw);
    d1.setAttribute('stroke-dasharray', '6 3');
    d1.setAttribute('opacity', '0.7');
    svg.appendChild(d1);

    var d2 = document.createElementNS(SVG_NS, 'line');
    d2.setAttribute('x1', ix(startCol + 2));
    d2.setAttribute('y1', iy(startRow));
    d2.setAttribute('x2', ix(startCol));
    d2.setAttribute('y2', iy(startRow + 2));
    d2.setAttribute('stroke', color);
    d2.setAttribute('stroke-width', sw);
    d2.setAttribute('stroke-dasharray', '6 3');
    d2.setAttribute('opacity', '0.7');
    svg.appendChild(d2);
}

function drawCornerMarks(svg, col, row, color, sw) {
    var ix = function (c) { return BOARD_PAD + c * CELL_SIZE; };
    var iy = function (r) { return BOARD_PAD + r * CELL_SIZE; };
    var cx = ix(col);
    var cy = iy(row);
    var gap = 4;
    var len = 10;

    var dirs = [[-1, -1], [1, -1], [-1, 1], [1, 1]];

    for (var i = 0; i < dirs.length; i++) {
        var dx = dirs[i][0];
        var dy = dirs[i][1];
        var nc = col + dx;
        if (nc < 0 || nc >= COLS) continue;

        var h = document.createElementNS(SVG_NS, 'line');
        h.setAttribute('x1', cx + dx * gap);
        h.setAttribute('y1', cy + dy * gap);
        h.setAttribute('x2', cx + dx * (gap + len));
        h.setAttribute('y2', cy + dy * gap);
        h.setAttribute('stroke', color);
        h.setAttribute('stroke-width', sw);
        svg.appendChild(h);

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
