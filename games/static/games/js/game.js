// ──────────────────────────────────────────────
//  Xiangqi Game — Board Renderer & Game Logic
// ──────────────────────────────────────────────

// ── Piece Name Mapping ──
const PIECE_NAMES = {
    rK: '\u5E25', rA: '\u4ED5', rE: '\u76F8', rN: '傌', rH: '傌', rR: '俥', rC: '炮', rP: '\u5175',
    bK: '\u5C07', bA: '\u58EB', bE: '\u8C61', bN: '\u99AC', bH: '\u99AC', bR: '\u8ECA', bC: '\u7832', bP: '\u5352'
};

// ── Board Constants ──
const COLS = 9;
const ROWS = 10;
const CELL_SIZE = 64;
const BOARD_PAD = 32;
const BOARD_W = (COLS - 1) * CELL_SIZE;
const BOARD_H = (ROWS - 1) * CELL_SIZE;
const PIECE_SIZE = Math.round(CELL_SIZE * 0.82);
const HINT_SIZE = 14;
const FONT_SIZE = Math.round(PIECE_SIZE * 0.58);

// ── SVG namespace ──
const SVG_NS = 'http://www.w3.org/2000/svg';

// ── Game State ──
let gameId = null;
let boardState = [];
let currentTurn = '';
let status = '';
let playerSide = '';
let aiSide = '';
let lastMove = null;
let selectedCell = null;
let legalMoves = [];
let isAnimating = false;
let inCheck = null; // 'r', 'b', or null
window.gameLocked = false;

// ── DOM (assigned in initGame after DOMContentLoaded) ──
var boardEl = null;
var statusDisplay = null;
var gameStatusLog = null;
var chatLog = null;

// ── CSRF ──
function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}
const csrftoken = getCookie('csrftoken');

// ═══════════════════════════════════════════════
//  Sound Effects (Web Audio API)
// ═══════════════════════════════════════════════

var _audioCtx = null;
function getAudioCtx() {
    if (!_audioCtx) {
        _audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    return _audioCtx;
}

// "Cạch" — woody thump when a piece lands
function playMoveSound() {
    try {
        var ctx = getAudioCtx();
        var buf = ctx.createBuffer(1, ctx.sampleRate * 0.12, ctx.sampleRate);
        var data = buf.getChannelData(0);
        for (var i = 0; i < data.length; i++) {
            var t = i / ctx.sampleRate;
            // Low thump: decaying sine at ~180 Hz
            data[i] = Math.sin(2 * Math.PI * 180 * t) * Math.exp(-t * 40);
            // Add soft click transient
            if (i < 80) data[i] += (Math.random() * 2 - 1) * (1 - i / 80) * 0.5;
        }
        var src = ctx.createBufferSource();
        src.buffer = buf;
        // Slight low-pass to make it warmer
        var filter = ctx.createBiquadFilter();
        filter.type = 'lowpass';
        filter.frequency.value = 900;
        var gain = ctx.createGain();
        gain.gain.value = 0.65;
        src.connect(filter);
        filter.connect(gain);
        gain.connect(ctx.destination);
        src.start();
    } catch (e) { /* silence */ }
}

// "Tick" — sharp crack when a piece is captured
function playCaptureSound() {
    try {
        var ctx = getAudioCtx();
        var buf = ctx.createBuffer(1, ctx.sampleRate * 0.1, ctx.sampleRate);
        var data = buf.getChannelData(0);
        for (var i = 0; i < data.length; i++) {
            var t = i / ctx.sampleRate;
            // Sharp crack: noise burst + mid-range tone
            var noise = (Math.random() * 2 - 1) * Math.exp(-t * 80);
            var tone = Math.sin(2 * Math.PI * 900 * t) * Math.exp(-t * 60) * 0.5;
            data[i] = noise + tone;
        }
        var src = ctx.createBufferSource();
        src.buffer = buf;
        var filter = ctx.createBiquadFilter();
        filter.type = 'bandpass';
        filter.frequency.value = 1800;
        filter.Q.value = 0.8;
        var gain = ctx.createGain();
        gain.gain.value = 0.8;
        src.connect(filter);
        filter.connect(gain);
        gain.connect(ctx.destination);
        src.start();
    } catch (e) { /* silence */ }
}

// "Ping" — metallic ring for check announcement
function playCheckSound() {
    try {
        var ctx = getAudioCtx();
        var duration = 0.55;
        var buf = ctx.createBuffer(1, Math.ceil(ctx.sampleRate * duration), ctx.sampleRate);
        var data = buf.getChannelData(0);
        for (var i = 0; i < data.length; i++) {
            var t = i / ctx.sampleRate;
            // Metallic ping: two harmonics with long decay
            var fundamental = Math.sin(2 * Math.PI * 880 * t) * Math.exp(-t * 8);
            var harmonic = Math.sin(2 * Math.PI * 1760 * t) * Math.exp(-t * 12) * 0.4;
            var shimmer = Math.sin(2 * Math.PI * 2640 * t) * Math.exp(-t * 18) * 0.15;
            data[i] = fundamental + harmonic + shimmer;
        }
        var src = ctx.createBufferSource();
        src.buffer = buf;
        var gain = ctx.createGain();
        gain.gain.value = 0.42;
        src.connect(gain);
        gain.connect(ctx.destination);
        src.start();
    } catch (e) { /* silence */ }
}

// ── Check Effects: text overlay + board shake + sound ──
var _checkOverlayTimer = null;
function triggerCheckEffects() {
    // 1. Metallic ping
    playCheckSound();

    // 2. Show "將軍" text overlay
    var overlay = document.getElementById('check-overlay');
    if (overlay) {
        // Set text based on who is in check (for flavour)
        overlay.textContent = '將軍';
        // Re-trigger animation by removing then re-adding class
        overlay.classList.remove('show');
        void overlay.offsetWidth; // force reflow
        overlay.classList.add('show');

        clearTimeout(_checkOverlayTimer);
        _checkOverlayTimer = setTimeout(function () {
            overlay.classList.remove('show');
        }, 1450);
    }

    // 3. Board shake
    var wrapper = document.getElementById('boardWrapper');
    if (wrapper) {
        wrapper.classList.remove('board--shaking');
        void wrapper.offsetWidth; // force reflow
        wrapper.classList.add('board--shaking');
        setTimeout(function () {
            wrapper.classList.remove('board--shaking');
        }, 250);
    }
}

// ═══════════════════════════════════════════════
//  SVG Grid Builder
// ═══════════════════════════════════════════════
function createBoardSVG() {
    const svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('class', 'board-svg');
    svg.setAttribute('viewBox', '0 0 ' + (BOARD_W + BOARD_PAD * 2) + ' ' + (BOARD_H + BOARD_PAD * 2));
    svg.setAttribute('preserveAspectRatio', 'xMidYMid meet');

    const strokeColor = '#8b6c42';
    const strokeWidth = 1.5;
    const thinStroke = 1;

    var ix = function (c) { return BOARD_PAD + c * CELL_SIZE; };
    var iy = function (r) { return BOARD_PAD + r * CELL_SIZE; };

    // Horizontal lines (10)
    for (var r = 0; r < ROWS; r++) {
        var line = document.createElementNS(SVG_NS, 'line');
        line.setAttribute('x1', ix(0));
        line.setAttribute('y1', iy(r));
        line.setAttribute('x2', ix(COLS - 1));
        line.setAttribute('y2', iy(r));
        line.setAttribute('stroke', strokeColor);
        line.setAttribute('stroke-width', strokeWidth);
        svg.appendChild(line);
    }

    // Vertical lines (9) - inner 7 break at river
    for (var c = 0; c < COLS; c++) {
        if (c === 0 || c === COLS - 1) {
            var vline = document.createElementNS(SVG_NS, 'line');
            vline.setAttribute('x1', ix(c));
            vline.setAttribute('y1', iy(0));
            vline.setAttribute('x2', ix(c));
            vline.setAttribute('y2', iy(ROWS - 1));
            vline.setAttribute('stroke', strokeColor);
            vline.setAttribute('stroke-width', strokeWidth);
            svg.appendChild(vline);
        } else {
            var topLine = document.createElementNS(SVG_NS, 'line');
            topLine.setAttribute('x1', ix(c));
            topLine.setAttribute('y1', iy(0));
            topLine.setAttribute('x2', ix(c));
            topLine.setAttribute('y2', iy(4));
            topLine.setAttribute('stroke', strokeColor);
            topLine.setAttribute('stroke-width', strokeWidth);
            svg.appendChild(topLine);

            var botLine = document.createElementNS(SVG_NS, 'line');
            botLine.setAttribute('x1', ix(c));
            botLine.setAttribute('y1', iy(5));
            botLine.setAttribute('x2', ix(c));
            botLine.setAttribute('y2', iy(ROWS - 1));
            botLine.setAttribute('stroke', strokeColor);
            botLine.setAttribute('stroke-width', strokeWidth);
            svg.appendChild(botLine);
        }
    }

    // Palace Diagonals
    drawPalace(svg, 3, 0, strokeColor, thinStroke);
    drawPalace(svg, 3, 7, strokeColor, thinStroke);

    // Cannon positions corner marks
    var cannonPositions = [[1, 2], [7, 2], [1, 7], [7, 7]];
    for (var i = 0; i < cannonPositions.length; i++) {
        drawCornerMarks(svg, cannonPositions[i][0], cannonPositions[i][1], strokeColor, thinStroke);
    }

    // Pawn positions corner marks
    var pawnPositions = [
        [0, 3], [2, 3], [4, 3], [6, 3], [8, 3],
        [0, 6], [2, 6], [4, 6], [6, 6], [8, 6]
    ];
    for (var i = 0; i < pawnPositions.length; i++) {
        drawCornerMarks(svg, pawnPositions[i][0], pawnPositions[i][1], strokeColor, thinStroke);
    }

    // River Text
    var riverY = (iy(4) + iy(5)) / 2;

    var textLeft = document.createElementNS(SVG_NS, 'text');
    textLeft.setAttribute('x', ix(1.8));
    textLeft.setAttribute('y', riverY + 12);
    textLeft.setAttribute('font-family', "'Ma Shan Zheng', 'KaiTi', cursive");
    textLeft.setAttribute('font-size', '36');
    textLeft.setAttribute('fill', strokeColor);
    textLeft.setAttribute('opacity', '0.55');
    textLeft.setAttribute('text-anchor', 'middle');
    textLeft.setAttribute('letter-spacing', '8');
    textLeft.textContent = '\u695A\u6CB3';
    svg.appendChild(textLeft);

    var textRight = document.createElementNS(SVG_NS, 'text');
    textRight.setAttribute('x', ix(6.2));
    textRight.setAttribute('y', riverY + 12);
    textRight.setAttribute('font-family', "'Ma Shan Zheng', 'KaiTi', cursive");
    textRight.setAttribute('font-size', '36');
    textRight.setAttribute('fill', strokeColor);
    textRight.setAttribute('opacity', '0.55');
    textRight.setAttribute('text-anchor', 'middle');
    textRight.setAttribute('letter-spacing', '8');
    textRight.textContent = '\u6F22\u754C';
    svg.appendChild(textRight);

    // Coordinates (1-9)
    // Top (Black side): 1 to 9 (Left to Right)
    for (var i = 0; i < 9; i++) {
        var txt = document.createElementNS(SVG_NS, 'text');
        txt.setAttribute('x', ix(i));
        txt.setAttribute('y', BOARD_PAD - 12);
        txt.setAttribute('font-family', 'sans-serif');
        txt.setAttribute('font-size', '14');
        txt.setAttribute('fill', strokeColor);
        txt.setAttribute('opacity', '0.8');
        txt.setAttribute('text-anchor', 'middle');
        txt.textContent = (i + 1).toString();
        svg.appendChild(txt);
    }

    // Bottom (Red side): 9 to 1 (Left to Right)
    for (var i = 0; i < 9; i++) {
        var txt = document.createElementNS(SVG_NS, 'text');
        txt.setAttribute('x', ix(i));
        txt.setAttribute('y', iy(ROWS - 1) + 24);
        txt.setAttribute('font-family', 'sans-serif');
        txt.setAttribute('font-size', '14');
        txt.setAttribute('fill', strokeColor);
        txt.setAttribute('opacity', '0.8');
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
    svg.appendChild(d1);

    var d2 = document.createElementNS(SVG_NS, 'line');
    d2.setAttribute('x1', ix(startCol + 2));
    d2.setAttribute('y1', iy(startRow));
    d2.setAttribute('x2', ix(startCol));
    d2.setAttribute('y2', iy(startRow + 2));
    d2.setAttribute('stroke', color);
    d2.setAttribute('stroke-width', sw);
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

// ═══════════════════════════════════════════════
//  Board Rendering
// ═══════════════════════════════════════════════

var boardSvgEl = null;

function initBoardStructure() {
    var totalW = BOARD_W + BOARD_PAD * 2;
    var totalH = BOARD_H + BOARD_PAD * 2;
    boardEl.style.width = totalW + 'px';
    boardEl.style.height = totalH + 'px';

    boardSvgEl = createBoardSVG();
    boardEl.appendChild(boardSvgEl);
}

function renderBoard(shouldAnimate) {
    var px = function (c) { return BOARD_PAD + c * CELL_SIZE; };
    var py = function (r) { return BOARD_PAD + r * CELL_SIZE; };

    // ── Snapshot existing pieces by (row,col) ──
    var existingByPos = {};   // "r,c" → element
    var existingPieces = Array.from(boardEl.getElementsByClassName('piece'));
    existingPieces.forEach(function (el) {
        // Skip pieces that are currently fading out
        if (el.classList.contains('piece--captured')) return;
        var key = el.dataset.row + ',' + el.dataset.col;
        existingByPos[key] = el;
    });

    // ── Identify the sliding piece & captured piece ──
    var slidingEl = null;
    var capturedEl = null;
    var slideFromLeft = 0, slideFromTop = 0;

    if (shouldAnimate && lastMove) {
        console.log("Animation triggered for move:", lastMove);
        var fromKey = lastMove.from[0] + ',' + lastMove.from[1];
        var toKey = lastMove.to[0] + ',' + lastMove.to[1];

        // The piece that was at lastMove.from is the one that moved
        if (existingByPos[fromKey]) {
            slidingEl = existingByPos[fromKey];
            console.log("Found sliding piece:", slidingEl.dataset.piece, "at", fromKey);
            // Record its current pixel position BEFORE we move it
            slideFromLeft = parseFloat(slidingEl.style.left) || 0;
            slideFromTop = parseFloat(slidingEl.style.top) || 0;
            // Remove from snapshot so it isn't double-matched
            delete existingByPos[fromKey];
        } else {
            console.warn("Sliding piece NOT found at", fromKey);
        }

        // The piece that was at lastMove.to is the captured piece
        if (lastMove.captured && existingByPos[toKey]) {
            capturedEl = existingByPos[toKey];
            console.log("Found captured piece:", capturedEl.dataset.piece, "at", toKey);
            delete existingByPos[toKey];
        }
    }

    // ── Remove non-SVG, non-piece children (markers, hints) ──
    var children = Array.from(boardEl.children);
    for (var i = 0; i < children.length; i++) {
        var ch = children[i];
        if (ch === boardSvgEl) continue;
        if (ch.classList.contains('piece')) continue; // handle pieces separately
        boardEl.removeChild(ch);
    }

    // ── Old Position Marker (Persistent) ──
    if (lastMove) {
        var r = lastMove.from[0];
        var c = lastMove.from[1];
        var marker = document.createElement('div');
        marker.className = 'old-pos-marker';
        marker.style.left = px(c) + 'px';
        marker.style.top = py(r) + 'px';
        boardEl.appendChild(marker);
    }
    if (capturedEl) {
        capturedEl.classList.add('piece--captured');
        // Remove from DOM after animation
        setTimeout(function () {
            if (capturedEl.parentNode) capturedEl.parentNode.removeChild(capturedEl);
        }, 180);
    }

    // ── Build pool of remaining existing pieces by code ──
    var availableByCode = {};
    Object.keys(existingByPos).forEach(function (key) {
        var el = existingByPos[key];
        var code = el.dataset.piece;
        if (!availableByCode[code]) availableByCode[code] = [];
        availableByCode[code].push(el);
    });

    // ── Compute capture targets ──
    var captureTargets = getCaptureTargets();

    // ── Place pieces for new board state ──
    var usedElements = new Set();
    if (slidingEl) usedElements.add(slidingEl);
    if (capturedEl) usedElements.add(capturedEl);

    for (var r = 0; r < ROWS; r++) {
        for (var c = 0; c < COLS; c++) {
            var code = boardState[r][c];
            if (!code) continue;

            var pieceEl = null;
            var newLeft = (px(c) - PIECE_SIZE / 2);
            var newTop = (py(r) - PIECE_SIZE / 2);

            // Is this the destination of the sliding piece?
            if (slidingEl && lastMove &&
                r === lastMove.to[0] && c === lastMove.to[1]) {
                pieceEl = slidingEl;
            } else {
                // Try to reuse an existing element of same code
                if (availableByCode[code] && availableByCode[code].length > 0) {
                    pieceEl = availableByCode[code].pop();
                    usedElements.add(pieceEl);
                } else {
                    // Create new
                    pieceEl = createPiece(code);
                }
            }

            // Update data attributes
            pieceEl.dataset.row = r;
            pieceEl.dataset.col = c;
            pieceEl.dataset.piece = code;
            pieceEl.dataset.side = code.charAt(0);

            // Update position
            pieceEl.style.left = newLeft + 'px';
            pieceEl.style.top = newTop + 'px';

            // Selection state
            if (selectedCell && selectedCell[0] === r && selectedCell[1] === c) {
                pieceEl.classList.add('selected');
            } else {
                pieceEl.classList.remove('selected');
            }

            // Last Move Target State (Glow Ring)
            // If animating this piece, defer adding the ring until animation ends
            var isTarget = (lastMove && lastMove.to[0] === r && lastMove.to[1] === c);
            var isAnimatingThis = (slidingEl && shouldAnimate && pieceEl === slidingEl);

            if (isTarget && !isAnimatingThis) {
                pieceEl.classList.add('last-move-target');
            } else {
                pieceEl.classList.remove('last-move-target');
            }

            // Capture target state (purple ring)
            if (captureTargets.has(r + ',' + c)) {
                pieceEl.classList.add('capture-target');
            } else {
                pieceEl.classList.remove('capture-target');
            }

            // Check indicator (red ring around king)
            var isKing = (code === 'rK' || code === 'bK');
            var side = code.charAt(0);
            if (isKing && inCheck === side) {
                pieceEl.classList.add('king-in-check');
            } else {
                pieceEl.classList.remove('king-in-check');
            }

            // Click handler
            (function (row, col) {
                pieceEl.onclick = function (e) {
                    e.stopPropagation();
                    if (isAnimating) return;
                    handleCellClick(row, col);
                };
            })(r, c);

            // If detached or new, append it
            if (!pieceEl.parentNode) {
                boardEl.appendChild(pieceEl);
            }
        }
    }

    // ── Remove unused pieces ──
    existingPieces.forEach(function (el) {
        if (el.classList.contains('piece--captured')) return; // already handled
        if (!usedElements.has(el) && !document.querySelector('[data-row="' + el.dataset.row + '"][data-col="' + el.dataset.col + '"]')) {
            // Check if this element is still needed (matched by the loop above)
            // Simple check: if its row/col data doesn't match any board cell with its code
            var er = parseInt(el.dataset.row);
            var ec = parseInt(el.dataset.col);
            if (!boardState[er] || boardState[er][ec] !== el.dataset.piece) {
                if (el.parentNode) el.parentNode.removeChild(el);
            }
        }
    });

    // ── FLIP Animation for sliding piece ──
    if (slidingEl && shouldAnimate && lastMove) {
        var targetLeft = parseFloat(slidingEl.style.left) || 0;
        var targetTop = parseFloat(slidingEl.style.top) || 0;
        var deltaX = slideFromLeft - targetLeft;
        var deltaY = slideFromTop - targetTop;

        if (deltaX !== 0 || deltaY !== 0) {
            // Lock interactions
            isAnimating = true;
            boardEl.classList.add('board--animating');

            isAnimating = true;
            boardEl.classList.add('board--animating');

            // (Marker is now handled declaratively in renderBoard, 
            // no need to call showOldPosMarker here if it just fades)

            // FLIP: Immediately offset to old position (no transition)

            // FLIP: Immediately offset to old position (no transition)
            slidingEl.style.transition = 'none';
            slidingEl.style.transform = 'translate(' + deltaX + 'px, ' + deltaY + 'px)';

            // Next frame: enable transition and slide to final position
            requestAnimationFrame(function () {
                requestAnimationFrame(function () {
                    slidingEl.style.transition = '';
                    slidingEl.classList.add('piece--sliding');
                    slidingEl.style.transform = 'translate(0, 0)';

                    var onEnd = function () {
                        slidingEl.classList.remove('piece--sliding');
                        slidingEl.style.transform = '';

                        // Add ring now that animation is done
                        slidingEl.classList.add('last-move-target');

                        isAnimating = false;
                        boardEl.classList.remove('board--animating');
                        slidingEl.removeEventListener('transitionend', onEnd);
                    };
                    slidingEl.addEventListener('transitionend', onEnd);

                    // Safety timeout in case transitionend doesn't fire
                    setTimeout(function () {
                        if (isAnimating) {
                            slidingEl.classList.remove('piece--sliding');
                            slidingEl.style.transform = '';
                            slidingEl.classList.add('last-move-target'); // Ensure ring is added on timeout too
                            isAnimating = false;
                            boardEl.classList.remove('board--animating');
                        }
                    }, 520);
                });
            });
        }
    }

    // ── Hint Dots ──
    if (selectedCell) {
        renderHints(px, py);
    }
}

function createPiece(code) {
    var isRed = code.startsWith('r');
    var charName = PIECE_NAMES[code] || '?';

    var piece = document.createElement('div');
    piece.className = 'piece ' + (isRed ? 'piece-red' : 'piece-black');
    piece.dataset.piece = code;
    piece.dataset.side = code.charAt(0);
    piece.dataset.row = '0';
    piece.dataset.col = '0';

    piece.style.width = PIECE_SIZE + 'px';
    piece.style.height = PIECE_SIZE + 'px';

    var txt = document.createElement('span');
    txt.className = 'piece-text';
    txt.style.fontSize = FONT_SIZE + 'px';
    txt.textContent = charName;
    piece.appendChild(txt);

    return piece;
}

function renderHints(px, py) {
    if (!selectedCell) return;
    var sr = selectedCell[0];
    var sc = selectedCell[1];

    for (var i = 0; i < legalMoves.length; i++) {
        var m = legalMoves[i];
        if (m.from[0] !== sr || m.from[1] !== sc) continue;
        var tr = m.to[0];
        var tc = m.to[1];
        var dot = document.createElement('div');
        dot.className = 'hint-dot';
        dot.style.width = HINT_SIZE + 'px';
        dot.style.height = HINT_SIZE + 'px';
        dot.style.left = (px(tc) - HINT_SIZE / 2) + 'px';
        dot.style.top = (py(tr) - HINT_SIZE / 2) + 'px';
        boardEl.appendChild(dot);
    }
}

function getCaptureTargets() {
    var targets = new Set();
    if (!selectedCell) return targets;
    if (currentTurn !== playerSide || status !== 'ongoing') return targets;
    var sr = selectedCell[0];
    var sc = selectedCell[1];
    var enemySide = (playerSide === 'r') ? 'b' : 'r';
    for (var i = 0; i < legalMoves.length; i++) {
        var m = legalMoves[i];
        if (m.from[0] !== sr || m.from[1] !== sc) continue;
        var tr = m.to[0];
        var tc = m.to[1];
        var dest = boardState[tr][tc];
        if (dest && dest.charAt(0) === enemySide) {
            targets.add(tr + ',' + tc);
        }
    }
    return targets;
}

// (Function removed as we render declaratively now)

// ═══════════════════════════════════════════════
//  Game Logic
// ═══════════════════════════════════════════════

function initGame(config) {
    // Assign DOM refs here — DOM is guaranteed to exist by the time initGame() is called
    boardEl = document.getElementById('board');
    statusDisplay = document.getElementById('status-display');
    gameStatusLog = document.getElementById('game-status-log');
    chatLog = document.querySelector('.chat-log');

    // Attach board click listener
    boardEl.addEventListener('click', function (e) {
        if (isAnimating) return;
        var rect = boardEl.getBoundingClientRect();
        var x = e.clientX - rect.left;
        var y = e.clientY - rect.top;
        var c = Math.round((x - BOARD_PAD) / CELL_SIZE);
        var r = Math.round((y - BOARD_PAD) / CELL_SIZE);
        if (c >= 0 && c < COLS && r >= 0 && r < ROWS) {
            handleCellClick(r, c);
        }
    });

    gameId = config.gameId;
    boardState = config.boardState;
    currentTurn = config.currentTurn;
    status = config.status;
    playerSide = config.playerSide;
    legalMoves = config.legalMoves || [];
    lastMove = config.lastMove || null;
    inCheck = config.inCheck || null;

    // Un-suspend AudioContext on first user interaction (browser autoplay policy)
    document.addEventListener('click', function resumeAudio() {
        var ctx = getAudioCtx();
        if (ctx.state === 'suspended') ctx.resume();
        document.removeEventListener('click', resumeAudio);
    }, { once: true });

    initBoardStructure();
    renderBoard(false);
    updateStatusUI();
    initTurnIndicator();
}

function handleCellClick(r, c) {
    if (isAnimating) return;
    if (window.gameLocked) return;
    if (status !== 'ongoing') return;

    var pieceCode = boardState[r][c];
    var isMyPiece = pieceCode && pieceCode.startsWith(playerSide);

    if (selectedCell) {
        if (selectedCell[0] === r && selectedCell[1] === c) {
            selectedCell = null;
            renderBoard(false);
            return;
        }

        if (isMyPiece) {
            selectedCell = [r, c];
            renderBoard(false);
            return;
        }

        if (currentTurn !== playerSide) return;

        var moveData = {
            from: selectedCell,
            to: [r, c]
        };

        sendMove(moveData);
        selectedCell = null;
    } else {
        if (isMyPiece) {
            selectedCell = [r, c];
            renderBoard(false);
        }
    }
}

function sendMove(move) {
    fetch('/api/games/' + gameId + '/move', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRFToken': csrftoken
        },
        body: JSON.stringify(move)
    })
        .then(function (res) { return res.json(); })
        .then(function (data) {
            if (data.ok) {
                updateGameState(data);
                logMove(move, "Player");

                if (data.status === 'ongoing' && data.current_turn !== playerSide) {
                    startPolling();
                }
            } else {
                showGameToast(data.message, 'warning');
            }
        })
        .catch(function (err) {
            console.error(err);
            showGameToast("Mất kết nối với giang hồ", 'warning');
        });
}

function updateGameState(data) {
    var prevLastMove = lastMove;
    var prevInCheck = inCheck;
    boardState = data.board_state;
    currentTurn = data.current_turn;
    status = data.status;
    lastMove = data.last_move;
    legalMoves = data.legal_moves || [];
    inCheck = data.in_check || null;

    // Fire check effects only when check newly appears (not on every poll)
    if (inCheck && inCheck !== prevInCheck) {
        triggerCheckEffects();
    }

    // Animate if there's a new move that differs from the previous one
    var shouldAnimate = !!(lastMove && (!prevLastMove ||
        lastMove.from[0] !== prevLastMove.from[0] ||
        lastMove.from[1] !== prevLastMove.from[1] ||
        lastMove.to[0] !== prevLastMove.to[0] ||
        lastMove.to[1] !== prevLastMove.to[1]));

    // ── Sound Effects ──
    if (shouldAnimate && lastMove) {
        if (lastMove.captured) {
            playCaptureSound();
        } else {
            playMoveSound();
        }
    }

    updateStatusUI();
    renderBoard(shouldAnimate);

    if (lastMove && currentTurn === playerSide) {
        logMove({ from: lastMove.from, to: lastMove.to }, "AI");
    }

    if (status !== 'ongoing') {
        if (window.gameTimer) window.gameTimer.stop(true);
    }

    if (status === 'finished') {
        // Determine whether user won, lost, or drew
        var gameStatus = "draw";
        if (data.winner) {
            gameStatus = (data.winner === playerSide) ? "win" : "lose";
        } else if (data.result === "lose") {
            gameStatus = "lose";
        }

        var reason = data.reason || "";
        if (!reason && inCheck && data.winner) {
            reason = "checkmate";
        }

        if (window.showEndgame) {
            window.showEndgame({
                status: gameStatus,
                winner: data.winner,
                my_side: playerSide,
                reason: reason,
                message: data.message
            });
        } else {
            setTimeout(function () { alert('Game Over! Winner: ' + data.winner); }, 100);
        }
        logSystem('Game Over. Winner: ' + data.winner);
    }
}

function updateStatusUI() {
    if (statusDisplay) {
        var text = status === 'ongoing' ? "Playing" : "Finished";
        if (status === 'ongoing') {
            text += currentTurn === playerSide ? " (Your Turn)" : " (Thinking...)";
        }
        statusDisplay.innerText = text;
    }
    updateTurnIndicator();
}

// ── Turn Indicator Logic ──
function initTurnIndicator() {
    // Set the correct avatar glyphs and name labels based on player's side
    var leftAvatar = document.getElementById('ppAvatarLeft');
    var rightAvatar = document.getElementById('ppAvatarRight');
    var leftName = document.getElementById('ppNameLeft');
    var rightName = document.getElementById('ppNameRight');
    if (!leftAvatar || !rightAvatar) return;

    // Left panel = Bạn (player), Right panel = Đối thủ (AI)
    // Red side uses 帥 (General, Red); Black side uses 將 (General, Black)
    if (playerSide === 'r') {
        leftAvatar.textContent = '帥';   // Red general
        rightAvatar.textContent = '將';   // Black general
    } else {
        leftAvatar.textContent = '將';   // Black general
        rightAvatar.textContent = '帥';   // Red general
    }
    if (leftName) leftName.textContent = 'Bạn';
    if (rightName) rightName.textContent = 'Đối thủ';

    updateTurnIndicator();
}

function updateTurnIndicator() {
    var leftPanel = document.getElementById('playerPanelLeft');
    var rightPanel = document.getElementById('playerPanelRight');
    if (!leftPanel || !rightPanel) return;

    var isMyTurn = (status === 'ongoing' && currentTurn === playerSide);
    var isAITurn = (status === 'ongoing' && currentTurn !== playerSide);

    leftPanel.classList.toggle('player-panel--active', isMyTurn);
    rightPanel.classList.toggle('player-panel--active', isAITurn);
}

function logMove(move, who) {
    if (!chatLog) return;
    var entry = document.createElement('div');
    entry.className = 'log-entry';
    entry.innerText = who + ': (' + move.from + ') -> (' + move.to + ')';
    chatLog.appendChild(entry);
    chatLog.scrollTop = chatLog.scrollHeight;
}

function logSystem(msg) {
    if (!chatLog) return;
    var entry = document.createElement('div');
    entry.className = 'log-entry system';
    entry.innerText = 'System: ' + msg;
    chatLog.appendChild(entry);
    chatLog.scrollTop = chatLog.scrollHeight;
}

// ═══════════════════════════════════════════════
//  Global Endgame Modals
// ═══════════════════════════════════════════════
window.showEndgame = function (result) {
    window.gameLocked = true; // Block UI interactions

    // Currently we only explicitly handle the "lose" screen as requested.
    // Winning and drawing might use different ones or the cuộn thư.
    if (result.status === "lose") {
        document.body.style.overflow = "hidden"; // Lock scroll

        var overlay = document.getElementById("loseOverlay");
        if (!overlay) return;

        var reasonText = document.getElementById("loseReason");
        if (reasonText) {
            var r = result.reason || "";
            if (r === "checkmate") {
                reasonText.textContent = "Bại do chiếu bí.";
            } else if (r === "resign") {
                reasonText.textContent = "Bại do nhận thua.";
            } else if (r === "timeout") {
                reasonText.textContent = "Bại do hết thời gian.";
            } else if (r === "disconnect") {
                reasonText.textContent = "Bại do rời trận.";
            } else {
                reasonText.textContent = "Thất bại.";
            }
        }

        overlay.hidden = false;

        // Trigger stamp animation
        var seal = document.getElementById("loseSeal");
        if (seal) {
            seal.classList.remove("lose-seal--stamped");
            void seal.offsetWidth; // trigger reflow
            setTimeout(function () {
                seal.classList.add("lose-seal--stamped");
                if (typeof playThud === "function") playThud();
                else if (typeof window.playThud === "function") window.playThud();
                // We'll optionally define playThud globally if needed, 
                // but let's assume it's in the inline script or we could use playMoveSound().
                else playMoveSound();
            }, 120);
        }
    } else {
        // Fallback for win/draw
        if (result.status === "draw") {
            if (typeof window.showEndgameModal === "function") {
                window.showEndgameModal("draw");
            } else {
                setTimeout(function () { alert("Game Drawn"); }, 100);
            }
        } else {
            // ── WIN SCREEN ──
            document.body.style.overflow = "hidden";

            var overlay = document.getElementById("winOverlay");
            if (!overlay) return;

            // Set reason text
            var reasonText = document.getElementById("winReason");
            if (reasonText) {
                var r = result.reason || "";
                if (r === "checkmate") {
                    reasonText.textContent = "Chiếu bí — đối thủ quy hàng.";
                } else if (r === "resign") {
                    reasonText.textContent = "Đối thủ đã nhận thua.";
                } else if (r === "timeout") {
                    reasonText.textContent = "Đối thủ hết thời gian.";
                } else {
                    reasonText.textContent = "Bạn đã đánh bại đối thủ!";
                }
            }

            // Show overlay
            overlay.hidden = false;

            // Spawn golden particles
            _spawnWinParticles();

            // Trigger seal stamp animation + sound after panel animation settles
            var seal = document.getElementById("winSeal");
            if (seal) {
                seal.classList.remove("win-seal--stamped");
                void seal.offsetWidth;
                setTimeout(function () {
                    seal.classList.add("win-seal--stamped");
                    if (typeof playThud === "function") playThud();
                    else if (typeof window.playThud === "function") window.playThud();
                    else playMoveSound();
                }, 300);
            }

            // Victory gong sound (after a short delay for dramatic buildup)
            setTimeout(function () { _playVictoryGong(); }, 150);
        }
    }
};

// ── Victory Gong Sound (Web Audio API — brass hit + bell shimmer) ──
function _playVictoryGong() {
    try {
        var ctx = new (window.AudioContext || window.webkitAudioContext)();
        var dur = 1.2;
        var buf = ctx.createBuffer(1, ctx.sampleRate * dur, ctx.sampleRate);
        var d = buf.getChannelData(0);
        for (var i = 0; i < d.length; i++) {
            var t = i / ctx.sampleRate;
            // Low brass hit (fundamental ~110 Hz)
            d[i] = Math.sin(2 * Math.PI * 110 * t) * Math.exp(-t * 3) * 0.35
                // Mid harmonic (220 Hz)
                + Math.sin(2 * Math.PI * 220 * t) * Math.exp(-t * 4) * 0.2
                // High bell shimmer (880 Hz)
                + Math.sin(2 * Math.PI * 880 * t) * Math.exp(-t * 8) * 0.12
                // Sparkle (1760 Hz, quiet)
                + Math.sin(2 * Math.PI * 1760 * t) * Math.exp(-t * 14) * 0.06
                // Noise burst for attack transient
                + (Math.random() * 2 - 1) * Math.exp(-t * 50) * 0.18;
        }
        var src = ctx.createBufferSource();
        var g = ctx.createGain();
        src.buffer = buf;
        g.gain.value = 0.5;
        src.connect(g);
        g.connect(ctx.destination);
        src.start();
    } catch (e) { /* silent fail */ }
}

// ── Spawn Golden Particles ──
function _spawnWinParticles() {
    var container = document.getElementById("winParticles");
    if (!container) return;
    container.innerHTML = ""; // Clear any old particles

    var count = 35;
    for (var i = 0; i < count; i++) {
        var p = document.createElement("div");
        p.className = "win-particle";

        // Random size 3–8px
        var size = 3 + Math.random() * 5;
        p.style.width = size + "px";
        p.style.height = size + "px";

        // Random horizontal position
        p.style.left = (Math.random() * 100) + "%";

        // Start from bottom area (random 70%–100%)
        p.style.bottom = (Math.random() * 30) + "%";

        // Gold color with slight variation
        var hue = 38 + Math.random() * 15;       // 38–53 (gold range)
        var sat = 85 + Math.random() * 15;        // 85–100%
        var light = 55 + Math.random() * 15;      // 55–70%
        p.style.background = "hsl(" + hue + "," + sat + "%," + light + "%)";
        p.style.boxShadow = "0 0 " + (size + 2) + "px hsla(" + hue + "," + sat + "%," + light + "%,0.5)";

        // Random animation duration and delay
        var duration = 3 + Math.random() * 4;     // 3–7s
        var delay = Math.random() * 2;             // 0–2s delay
        p.style.animationDuration = duration + "s";
        p.style.animationDelay = delay + "s";

        container.appendChild(p);
    }
}

var pollInterval = null;

function startPolling() {
    if (pollInterval) clearInterval(pollInterval);
    updateStatusUI();

    pollInterval = setInterval(function () {
        fetch('/api/games/' + gameId + '/')
            .then(function (res) { return res.json(); })
            .then(function (data) {
                if (data.ok) {
                    if (data.current_turn === playerSide || data.status === 'finished') {
                        clearInterval(pollInterval);
                        pollInterval = null;
                        updateGameState(data);
                    }
                }
            })
            .catch(function (err) {
                console.error("Polling error", err);
            });
    }, 1000);
}

// ═══════════════════════════════════════════════
//  Game Toasts (Thông báo hiển thị cổ trang)
// ═══════════════════════════════════════════════
window.showGameToast = function (message, type) {
    type = type || 'warning';
    var container = document.getElementById('game-toast-container');
    if (!container) return;

    var existingToasts = container.querySelectorAll('.game-toast:not(.hiding)');
    if (existingToasts.length > 0) {
        var lastToast = existingToasts[existingToasts.length - 1];
        var textNode = lastToast.querySelector('.game-toast-message');
        if (textNode && textNode.dataset.rawMessage === message) {
            var count = parseInt(lastToast.dataset.count || '0') + 1;
            lastToast.dataset.count = count;
            textNode.textContent = window.getToastDisplayMsg(message) + ' (x' + count + ')';

            clearTimeout(parseInt(lastToast.dataset.timeoutId));
            var newTimeoutId = setTimeout(function () {
                lastToast.classList.add('hiding');
                setTimeout(function () { if (lastToast.parentNode) lastToast.remove(); }, 300);
            }, 3000);
            lastToast.dataset.timeoutId = newTimeoutId;

            lastToast.style.transform = 'scale(1.02)';
            setTimeout(function () {
                if (!lastToast.classList.contains('hiding')) {
                    lastToast.style.transform = '';
                }
            }, 120);
            return;
        }
    }

    if (existingToasts.length >= 2) {
        var oldest = existingToasts[0];
        oldest.classList.add('hiding');
        setTimeout(function () { if (oldest.parentNode) oldest.remove(); }, 300);
    }

    var toast = document.createElement('div');
    toast.className = 'game-toast toast-' + type;
    toast.dataset.count = 1;

    var msgEl = document.createElement('div');
    msgEl.className = 'game-toast-message';
    msgEl.dataset.rawMessage = message;
    msgEl.textContent = window.getToastDisplayMsg(message);
    toast.appendChild(msgEl);

    container.appendChild(toast);

    var timeoutId = setTimeout(function () {
        toast.classList.add('hiding');
        setTimeout(function () { if (toast.parentNode) toast.remove(); }, 300);
    }, 3000);
    toast.dataset.timeoutId = timeoutId;
};

window.getToastDisplayMsg = function (message) {
    if (!message) return "Nước đi không hợp lệ.";
    var msg = message.toLowerCase();
    if (msg.includes("invalid move")) return "Nước đi không hợp lệ.";
    if (msg.includes("not your turn")) return "Chưa tới lượt xuất chiêu.";
    if (msg.includes("piece from")) return "Không thể điều binh tướng này.";
    if (msg.includes("check")) return "Tướng đang bị chiếu!";
    return message;
};
