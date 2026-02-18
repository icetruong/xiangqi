// ──────────────────────────────────────────────
//  piece-renderer.js — Piece creation, board
//  rendering, hints, and capture targets
//  Depends on: constants.js, svg-grid.js
// ──────────────────────────────────────────────

var boardSvgEl = null;

function initBoardStructure() {
    var totalW = BOARD_W + BOARD_PAD * 2;
    var totalH = BOARD_H + BOARD_PAD * 2;
    boardEl.style.width = totalW + 'px';
    boardEl.style.height = totalH + 'px';

    boardSvgEl = createBoardSVG();
    boardEl.appendChild(boardSvgEl);
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

function renderBoard(shouldAnimate) {
    var px = function (c) { return BOARD_PAD + c * CELL_SIZE; };
    var py = function (r) { return BOARD_PAD + r * CELL_SIZE; };

    // ── Snapshot existing pieces by (row,col) ──
    var existingByPos = {};
    var existingPieces = Array.from(boardEl.getElementsByClassName('piece'));
    existingPieces.forEach(function (el) {
        if (el.classList.contains('piece--captured')) return;
        var key = el.dataset.row + ',' + el.dataset.col;
        existingByPos[key] = el;
    });

    // ── Identify sliding & captured pieces ──
    var slidingEl = null;
    var capturedEl = null;
    var slideFromLeft = 0, slideFromTop = 0;

    if (shouldAnimate && lastMove) {
        var fromKey = lastMove.from[0] + ',' + lastMove.from[1];
        var toKey = lastMove.to[0] + ',' + lastMove.to[1];

        if (existingByPos[fromKey]) {
            slidingEl = existingByPos[fromKey];
            slideFromLeft = parseFloat(slidingEl.style.left) || 0;
            slideFromTop = parseFloat(slidingEl.style.top) || 0;
            delete existingByPos[fromKey];
        }

        if (lastMove.captured && existingByPos[toKey]) {
            capturedEl = existingByPos[toKey];
            delete existingByPos[toKey];
        }
    }

    // ── Remove non-SVG, non-piece children (markers, hints) ──
    var children = Array.from(boardEl.children);
    for (var i = 0; i < children.length; i++) {
        var ch = children[i];
        if (ch === boardSvgEl) continue;
        if (ch.classList.contains('piece')) continue;
        boardEl.removeChild(ch);
    }

    // ── Old Position Marker ──
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
        setTimeout(function () {
            if (capturedEl.parentNode) capturedEl.parentNode.removeChild(capturedEl);
        }, 180);
    }

    // ── Reuse pool ──
    var availableByCode = {};
    Object.keys(existingByPos).forEach(function (key) {
        var el = existingByPos[key];
        var code = el.dataset.piece;
        if (!availableByCode[code]) availableByCode[code] = [];
        availableByCode[code].push(el);
    });

    // ── Capture targets ──
    var captureTargets = getCaptureTargets();

    // ── Place pieces ──
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

            if (slidingEl && lastMove &&
                r === lastMove.to[0] && c === lastMove.to[1]) {
                pieceEl = slidingEl;
            } else {
                if (availableByCode[code] && availableByCode[code].length > 0) {
                    pieceEl = availableByCode[code].pop();
                    usedElements.add(pieceEl);
                } else {
                    pieceEl = createPiece(code);
                }
            }

            pieceEl.dataset.row = r;
            pieceEl.dataset.col = c;
            pieceEl.dataset.piece = code;
            pieceEl.dataset.side = code.charAt(0);
            pieceEl.style.left = newLeft + 'px';
            pieceEl.style.top = newTop + 'px';

            // Selection
            if (selectedCell && selectedCell[0] === r && selectedCell[1] === c) {
                pieceEl.classList.add('selected');
            } else {
                pieceEl.classList.remove('selected');
            }

            // Last-move ring
            var isTarget = (lastMove && lastMove.to[0] === r && lastMove.to[1] === c);
            var isAnimatingThis = (slidingEl && shouldAnimate && pieceEl === slidingEl);
            if (isTarget && !isAnimatingThis) {
                pieceEl.classList.add('last-move-target');
            } else {
                pieceEl.classList.remove('last-move-target');
            }

            // Capture ring
            if (captureTargets.has(r + ',' + c)) {
                pieceEl.classList.add('capture-target');
            } else {
                pieceEl.classList.remove('capture-target');
            }

            // Click handler
            (function (row, col) {
                pieceEl.onclick = function (e) {
                    e.stopPropagation();
                    if (isAnimating) return;
                    handleCellClick(row, col);
                };
            })(r, c);

            if (!pieceEl.parentNode) {
                boardEl.appendChild(pieceEl);
            }
        }
    }

    // ── Remove unused ──
    existingPieces.forEach(function (el) {
        if (el.classList.contains('piece--captured')) return;
        if (!usedElements.has(el)) {
            var er = parseInt(el.dataset.row);
            var ec = parseInt(el.dataset.col);
            if (!boardState[er] || boardState[er][ec] !== el.dataset.piece) {
                if (el.parentNode) el.parentNode.removeChild(el);
            }
        }
    });

    // ── FLIP Animation ──
    if (slidingEl && shouldAnimate && lastMove) {
        var targetLeft = parseFloat(slidingEl.style.left) || 0;
        var targetTop = parseFloat(slidingEl.style.top) || 0;
        var deltaX = slideFromLeft - targetLeft;
        var deltaY = slideFromTop - targetTop;

        if (deltaX !== 0 || deltaY !== 0) {
            isAnimating = true;
            boardEl.classList.add('board--animating');

            slidingEl.style.transition = 'none';
            slidingEl.style.transform = 'translate(' + deltaX + 'px, ' + deltaY + 'px)';

            requestAnimationFrame(function () {
                requestAnimationFrame(function () {
                    slidingEl.style.transition = '';
                    slidingEl.classList.add('piece--sliding');
                    slidingEl.style.transform = 'translate(0, 0)';

                    var onEnd = function () {
                        slidingEl.classList.remove('piece--sliding');
                        slidingEl.style.transform = '';
                        slidingEl.classList.add('last-move-target');
                        isAnimating = false;
                        boardEl.classList.remove('board--animating');
                        slidingEl.removeEventListener('transitionend', onEnd);
                    };
                    slidingEl.addEventListener('transitionend', onEnd);

                    setTimeout(function () {
                        if (isAnimating) {
                            slidingEl.classList.remove('piece--sliding');
                            slidingEl.style.transform = '';
                            slidingEl.classList.add('last-move-target');
                            isAnimating = false;
                            boardEl.classList.remove('board--animating');
                        }
                    }, 520);
                });
            });
        }
    }

    // ── Hint dots ──
    if (selectedCell) {
        renderHints(px, py);
    }
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
