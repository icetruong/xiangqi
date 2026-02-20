// ──────────────────────────────────────────────
//  game-logic.js — Step 4: Click interaction,
//  move submission, AI polling
//  Depends on: constants.js, piece-renderer.js
// ──────────────────────────────────────────────

// ── CSRF ──
function getCookie(name) {
    var v = null;
    if (document.cookie) {
        document.cookie.split(';').forEach(function (c) {
            c = c.trim();
            if (c.startsWith(name + '=')) v = decodeURIComponent(c.slice(name.length + 1));
        });
    }
    return v;
}
var csrftoken = getCookie('csrftoken');

// ── Interaction state ──
var selected = null;   // { row, col }
var legalSet = {};     // "r,c" -> "move" | "capture"
var isLocked = false;
var pollTimer = null;
var markersLayer = null;

// ── Init markers layer ──
function initMarkersLayer() {
    markersLayer = document.createElement('div');
    markersLayer.className = 'markers-layer';
    boardEl.appendChild(markersLayer);
}

// ── Enable piece clicks ──
function enablePieceClicks() {
    piecesLayer.style.pointerEvents = 'auto';
    piecesLayer.addEventListener('click', onPieceClick);
    boardEl.addEventListener('click', onBoardClick);
}

// ── Piece click ──
function onPieceClick(e) {
    var pieceEl = e.target.closest('.piece');
    if (!pieceEl) return;
    e.stopPropagation();

    if (isLocked) return;
    if (status !== 'ongoing') return;
    if (currentTurn !== playerSide) return;

    var r = parseInt(pieceEl.dataset.row);
    var c = parseInt(pieceEl.dataset.col);

    // Clicking a capturable enemy
    if (legalSet[r + ',' + c] === 'capture') {
        submitMove(selected.row, selected.col, r, c);
        return;
    }

    // Clicking own piece
    if (pieceEl.dataset.side === playerSide) {
        selectPiece(r, c);
        return;
    }
}

// ── Board (empty cell) click ──
function onBoardClick(e) {
    if (isLocked || !selected) return;
    if (status !== 'ongoing' || currentTurn !== playerSide) return;

    var rect = boardEl.getBoundingClientRect();
    var x = e.clientX - rect.left;
    var y = e.clientY - rect.top;

    // Convert click position to nearest col/row using % system
    var c = Math.round(x / rect.width * (COLS - 1));
    var r = Math.round(y / rect.height * (ROWS - 1));
    c = Math.max(0, Math.min(COLS - 1, c));
    r = Math.max(0, Math.min(ROWS - 1, r));

    if (legalSet[r + ',' + c] === 'move') {
        submitMove(selected.row, selected.col, r, c);
    } else {
        clearSelection();
    }
}

// ── Select piece & compute legal moves ──
function selectPiece(r, c) {
    selected = { row: r, col: c };
    legalSet = {};

    // Build legalSet from preloaded legalMoves array
    legalMoves.forEach(function (m) {
        if (m.from[0] === r && m.from[1] === c) {
            var tr = m.to[0], tc = m.to[1];
            var key = tr + ',' + tc;
            var destCode = boardState[tr][tc];
            legalSet[key] = (destCode && destCode.charAt(0) !== playerSide) ? 'capture' : 'move';
        }
    });

    renderMarkers();
    highlightSelected();
}

// ── Clear selection ──
function clearSelection() {
    selected = null;
    legalSet = {};
    renderMarkers();
    clearSelectedHighlight();
}

// ── Render intersection dots + capture rings ──
function renderMarkers() {
    if (!markersLayer) return;
    markersLayer.innerHTML = '';
    if (!selected) return;

    var pSz = getPieceSize();

    Object.keys(legalSet).forEach(function (key) {
        var parts = key.split(',');
        var r = parseInt(parts[0]);
        var c = parseInt(parts[1]);
        var type = legalSet[key];

        var cx = pieceX(c);
        var cy = pieceY(r);

        if (type === 'move') {
            var dot = document.createElement('div');
            dot.className = 'move-dot';
            var sz = Math.round(pSz * 0.30);
            dot.style.width = sz + 'px';
            dot.style.height = sz + 'px';
            dot.style.left = (cx - sz / 2) + 'px';
            dot.style.top = (cy - sz / 2) + 'px';
            markersLayer.appendChild(dot);
        } else {
            var ring = document.createElement('div');
            ring.className = 'capture-ring';
            var rsz = pSz + 10;
            ring.style.width = rsz + 'px';
            ring.style.height = rsz + 'px';
            ring.style.left = (cx - rsz / 2) + 'px';
            ring.style.top = (cy - rsz / 2) + 'px';
            markersLayer.appendChild(ring);
        }
    });
}

// ── Selected piece highlight ──
function highlightSelected() {
    clearSelectedHighlight();
    if (!selected) return;
    var all = piecesLayer.querySelectorAll('.piece');
    all.forEach(function (el) {
        if (parseInt(el.dataset.row) === selected.row &&
            parseInt(el.dataset.col) === selected.col) {
            el.classList.add('selected');
        }
    });
}

function clearSelectedHighlight() {
    if (!piecesLayer) return;
    piecesLayer.querySelectorAll('.piece.selected').forEach(function (el) {
        el.classList.remove('selected');
    });
}

// ── Submit move ──
function submitMove(fr, fc, tr, tc) {
    isLocked = true;
    clearSelection();

    fetch('/api/games/' + gameId + '/move', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRFToken': csrftoken },
        body: JSON.stringify({ from: [fr, fc], to: [tr, tc] })
    })
        .then(function (res) { return res.json(); })
        .then(function (data) {
            if (data.ok) {
                applyServerState(data);
                if (status === 'ongoing' && currentTurn !== playerSide) {
                    startPolling();
                } else {
                    isLocked = false;
                }
            } else {
                showToast(data.message || 'Invalid move');
                isLocked = false;
            }
        })
        .catch(function () {
            showToast('Network error');
            isLocked = false;
        });
}

// ── Apply server game state ──
function applyServerState(data) {
    boardState = data.board_state;
    currentTurn = data.current_turn;
    status = data.status;
    legalMoves = data.legal_moves || legalMoves;

    renderBoard(false);
    renderMarkers();
}

// ── Polling for AI move ──
function startPolling() {
    clearInterval(pollTimer);
    pollTimer = setInterval(function () {
        fetch('/api/games/' + gameId + '/')
            .then(function (r) { return r.json(); })
            .then(function (data) {
                if (!data.ok) return;
                if (data.current_turn === playerSide || data.status !== 'ongoing') {
                    clearInterval(pollTimer);
                    legalMoves = data.legal_moves || [];
                    applyServerState(data);
                    isLocked = false;
                    if (data.status !== 'ongoing') showGameOver(data);
                }
            });
    }, 1000);
}

// ── Game over ──
function showGameOver(data) {
    var msg = data.status === 'finished'
        ? (data.winner === playerSide ? '🏆 You Win!' : '💀 You Lose')
        : 'Game over';
    showToast(msg, 4000);
}

// ── Toast notification ──
var toastTimer = null;
function showToast(msg, duration) {
    var existing = document.getElementById('xiangqi-toast');
    if (existing) existing.remove();
    var el = document.createElement('div');
    el.id = 'xiangqi-toast';
    el.className = 'xiangqi-toast';
    el.textContent = msg;
    document.body.appendChild(el);
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { el.remove(); }, duration || 2500);
}
