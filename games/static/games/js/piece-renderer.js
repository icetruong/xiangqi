// ──────────────────────────────────────────────
//  piece-renderer.js — Step 3/4
//  Percentage-based placement from .grid-area.
//  Depends on: constants.js, svg-grid.js
// ──────────────────────────────────────────────

var boardSvgEl = null;
var piecesLayer = null;
var markersLayer = null;  // init by game-logic.js

// ── Compute piece size from live DOM ──
function getPieceSize() {
    var rect = boardEl.getBoundingClientRect();
    var cellW = rect.width / (COLS - 1);
    var cellH = rect.height / (ROWS - 1);
    return Math.round(0.85 * Math.min(cellW, cellH));
}

// ── % position of col/row intersection ──
function colPct(c) { return (c / (COLS - 1) * 100) + '%'; }
function rowPct(r) { return (r / (ROWS - 1) * 100) + '%'; }

// ── Pixel position helpers (for markers in game-logic.js) ──
function pieceX(c) {
    var rect = boardEl.getBoundingClientRect();
    return c / (COLS - 1) * rect.width;
}
function pieceY(r) {
    var rect = boardEl.getBoundingClientRect();
    return r / (ROWS - 1) * rect.height;
}

// ── Init SVG + pieces-layer ──
function initBoardStructure() {
    boardEl.style.width = '';  // let CSS control
    boardEl.style.height = '';

    boardSvgEl = createBoardSVG();
    boardEl.appendChild(boardSvgEl);

    piecesLayer = document.createElement('div');
    piecesLayer.className = 'pieces-layer';
    boardEl.appendChild(piecesLayer);
}

// ── Piece element factory ──
function createPiece(code) {
    var isRed = code.charAt(0) === 'r';
    var div = document.createElement('div');
    div.className = 'piece ' + (isRed ? 'piece-red' : 'piece-black');
    div.dataset.piece = code;
    div.dataset.side = code.charAt(0);
    var span = document.createElement('span');
    span.className = 'piece-text';
    span.textContent = PIECE_NAMES[code] || '?';
    div.appendChild(span);
    return div;
}

// ── Render all pieces (teleport, no animation) ──
function renderBoard(shouldAnimate) {
    if (!piecesLayer) return;
    piecesLayer.innerHTML = '';

    var sz = getPieceSize();

    for (var r = 0; r < ROWS; r++) {
        for (var c = 0; c < COLS; c++) {
            var code = boardState[r][c];
            if (!code) continue;

            var el = createPiece(code);
            el.dataset.row = r;
            el.dataset.col = c;
            el.style.width = sz + 'px';
            el.style.height = sz + 'px';
            el.style.fontSize = Math.round(sz * 0.52) + 'px';
            // Center on intersection via % + translate
            el.style.left = colPct(c);
            el.style.top = rowPct(r);
            el.style.transform = 'translate(-50%, -50%)';

            piecesLayer.appendChild(el);
        }
    }

    // Debug: show dot at every intersection
    if (DEBUG_GRID && markersLayer) {
        markersLayer.innerHTML = '';
        for (var dr = 0; dr < ROWS; dr++) {
            for (var dc = 0; dc < COLS; dc++) {
                var dot = document.createElement('div');
                dot.style.cssText = 'position:absolute;width:5px;height:5px;' +
                    'border-radius:50%;background:rgba(255,0,0,0.7);' +
                    'left:' + colPct(dc) + ';top:' + rowPct(dr) + ';' +
                    'transform:translate(-50%,-50%);pointer-events:none;z-index:99;';
                markersLayer.appendChild(dot);
            }
        }
    }
}

// ── Resize: re-render ──
window.addEventListener('resize', function () {
    if (boardState && boardState.length) renderBoard(false);
});
