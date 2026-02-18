// ──────────────────────────────────────────────
//  game-logic.js — Click handling, moves,
//  polling, status UI, logging
//  Depends on: constants.js, piece-renderer.js
// ──────────────────────────────────────────────

// ── CSRF ──
function getCookie(name) {
    var cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        var cookies = document.cookie.split(';');
        for (var i = 0; i < cookies.length; i++) {
            var cookie = cookies[i].trim();
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}
var csrftoken = getCookie('csrftoken');

// ── Cell Click Handler ──
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

// ── Send Move to Server ──
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

// ── Update Game State ──
function updateGameState(data) {
    var prevLastMove = lastMove;
    boardState = data.board_state;
    currentTurn = data.current_turn;
    status = data.status;
    lastMove = data.last_move;
    legalMoves = data.legal_moves || [];

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

// ── Status UI ──
function updateStatusUI() {
    if (statusDisplay) {
        var text = status === 'ongoing' ? "Playing" : "Finished";
        if (status === 'ongoing') {
            text += currentTurn === playerSide ? " (Your Turn)" : " (Thinking...)";
        }
        statusDisplay.innerText = text;
    }
}

// ── Logging ──
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

// ── Polling ──
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
