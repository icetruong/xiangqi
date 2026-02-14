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

// ── DOM ──
const boardEl = document.getElementById('board');
const statusDisplay = document.getElementById('status-display');
const gameStatusLog = document.getElementById('game-status-log');
const chatLog = document.querySelector('.chat-log');

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

function renderBoard() {
    var children = Array.from(boardEl.children);
    for (var i = 0; i < children.length; i++) {
        if (children[i] !== boardSvgEl) boardEl.removeChild(children[i]);
    }

    var px = function (c) { return BOARD_PAD + c * CELL_SIZE; };
    var py = function (r) { return BOARD_PAD + r * CELL_SIZE; };

    // Last move markers
    if (lastMove) {
        var positions = [lastMove.from, lastMove.to];
        for (var i = 0; i < positions.length; i++) {
            var mr = positions[i][0];
            var mc = positions[i][1];
            var marker = document.createElement('div');
            marker.className = 'last-move-marker';
            var size = PIECE_SIZE + 8;
            marker.style.width = size + 'px';
            marker.style.height = size + 'px';
            marker.style.left = (px(mc) - size / 2) + 'px';
            marker.style.top = (py(mr) - size / 2) + 'px';
            boardEl.appendChild(marker);
        }
    }

    // Pieces
    // We simply remove all existing pieces and re-create them for now,
    // *unless* we want full diffing.
    // To support animation with minimal change:
    // 1. Mark all existing pieces as 'stale'
    // 2. Iterate new board state
    // 3. For each piece:
    //    - Try to find a 'stale' piece of same type (e.g. 'rP').
    //    - If found, reuse it: update pos, unmark stale.
    //    - If not found, create new.
    // 4. Remove remaining 'stale' pieces.

    var existingPieces = Array.from(boardEl.getElementsByClassName('piece'));
    var available = {}; // key: pieceCode, val: [element]

    // Index existing pieces
    existingPieces.forEach(function (p) {
        var code = p.dataset.code;
        if (!available[code]) available[code] = [];
        available[code].push(p);
    });

    // We will build a list of pieces to keep/add
    var nextPieces = [];

    for (var r = 0; r < ROWS; r++) {
        for (var c = 0; c < COLS; c++) {
            var code = boardState[r][c];
            if (!code) continue;

            var pieceEl = null;

            // Try to reuse an existing piece of same code
            if (available[code] && available[code].length > 0) {
                pieceEl = available[code].pop();
            } else {
                // Create new
                pieceEl = createPiece(code);
            }

            // Update position
            pieceEl.style.left = (px(c) - PIECE_SIZE / 2) + 'px';
            pieceEl.style.top = (py(r) - PIECE_SIZE / 2) + 'px';

            // Selection state
            if (selectedCell && selectedCell[0] === r && selectedCell[1] === c) {
                pieceEl.classList.add('selected');
            } else {
                pieceEl.classList.remove('selected');
            }

            // Click handler (update closure)
            // Note: We need to update the onclick every time because r/c change
            (function (row, col) {
                pieceEl.onclick = function (e) {
                    e.stopPropagation();
                    handleCellClick(row, col);
                };
            })(r, c);

            nextPieces.push(pieceEl);

            // If it was detatched or new, append it
            if (!pieceEl.parentNode) {
                boardEl.appendChild(pieceEl);
            }
        }
    }

    // Remove any pieces that weren't reused (captured)
    // The 'available' arrays now contain only unused elements
    Object.keys(available).forEach(function (k) {
        available[k].forEach(function (el) {
            if (el.parentNode) el.parentNode.removeChild(el);
        });
    });

    // Hint Dots
    if (selectedCell) {
        renderHints(px, py);
    }
}

function createPiece(code) {
    var isRed = code.startsWith('r');
    var charName = PIECE_NAMES[code] || '?';

    var piece = document.createElement('div');
    piece.className = 'piece ' + (isRed ? 'piece-red' : 'piece-black');
    piece.dataset.code = code; // Store code for reuse/diffing

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

    initBoardStructure();
    renderBoard();
    updateStatusUI();
}

function handleCellClick(r, c) {
    if (status !== 'ongoing') return;

    var pieceCode = boardState[r][c];
    var isMyPiece = pieceCode && pieceCode.startsWith(playerSide);

    if (selectedCell) {
        if (selectedCell[0] === r && selectedCell[1] === c) {
            selectedCell = null;
            renderBoard();
            return;
        }

        if (isMyPiece) {
            selectedCell = [r, c];
            renderBoard();
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
            renderBoard();
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
    boardState = data.board_state;
    currentTurn = data.current_turn;
    status = data.status;
    lastMove = data.last_move;
    legalMoves = data.legal_moves || [];

    updateStatusUI();
    renderBoard();

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
