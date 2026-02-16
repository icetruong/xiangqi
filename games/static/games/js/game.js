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

// ── DOM ──
const boardEl = document.getElementById('board');
const statusDisplay = document.getElementById('status-display');
const gameStatusLog = document.getElementById('game-status-log');
const chatLog = document.querySelector('.chat-log');

// ── Board Interaction ──
boardEl.addEventListener('click', function (e) {
    if (isAnimating) return;
    const rect = boardEl.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    const c = Math.round((x - BOARD_PAD) / CELL_SIZE);
    const r = Math.round((y - BOARD_PAD) / CELL_SIZE);

    if (c >= 0 && c < COLS && r >= 0 && r < ROWS) {
        handleCellClick(r, c);
    }
});

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

    // ── Last move markers ──
    // (Legacy markers removed. We use transient .old-pos-marker and .last-move-target glow instead)


    // ── Fade out captured piece ──
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
            if (lastMove && lastMove.to[0] === r && lastMove.to[1] === c) {
                pieceEl.classList.add('last-move-target');
            } else {
                pieceEl.classList.remove('last-move-target');
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

            // Trigger "Old Position" marker effect
            showOldPosMarker(lastMove.from[0], lastMove.from[1]);

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

function showOldPosMarker(r, c) {
    if (!boardEl) return;
    var px = function (c) { return BOARD_PAD + c * CELL_SIZE; };
    var py = function (r) { return BOARD_PAD + r * CELL_SIZE; };

    var marker = document.createElement('div');
    marker.className = 'old-pos-marker';
    // Position at intersection
    marker.style.left = px(c) + 'px';
    marker.style.top = py(r) + 'px';

    boardEl.appendChild(marker);

    // Lifetime: 700-1200ms
    // Let's fade out starting at 700ms, remove at 1200ms
    setTimeout(function () {
        marker.style.opacity = '0';
    }, 700);

    setTimeout(function () {
        if (marker.parentNode) marker.parentNode.removeChild(marker);
    }, 1200);
}

// ═══════════════════════════════════════════════
//  Game Logic
// ═══════════════════════════════════════════════

function initGame(config) {
    gameId = config.gameId;
    boardState = config.boardState;
    currentTurn = config.currentTurn;
    status = config.status;
    playerSide = config.playerSide;
    legalMoves = config.legalMoves || [];
    lastMove = config.lastMove || null;

    initBoardStructure();
    renderBoard(false);
    updateStatusUI();
}

function handleCellClick(r, c) {
    if (isAnimating) return;
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
                alert('Error: ' + data.message);
            }
        })
        .catch(function (err) {
            console.error(err);
            alert("Server error");
        });
}

function updateGameState(data) {
    var prevLastMove = lastMove;
    boardState = data.board_state;
    currentTurn = data.current_turn;
    status = data.status;
    lastMove = data.last_move;
    legalMoves = data.legal_moves || [];

    // Animate if there's a new move that differs from the previous one
    var shouldAnimate = !!(lastMove && (!prevLastMove ||
        lastMove.from[0] !== prevLastMove.from[0] ||
        lastMove.from[1] !== prevLastMove.from[1] ||
        lastMove.to[0] !== prevLastMove.to[0] ||
        lastMove.to[1] !== prevLastMove.to[1]));

    updateStatusUI();
    renderBoard(shouldAnimate);

    if (lastMove && currentTurn === playerSide) {
        logMove({ from: lastMove.from, to: lastMove.to }, "AI");
    }

    if (status === 'finished') {
        setTimeout(function () { alert('Game Over! Winner: ' + data.winner); }, 100);
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
