// Game state
let gameId = null;
let boardState = [];
let currentTurn = "";
let status = "";
let playerSide = "";
let aiSide = "";
let lastMove = null;
let selectedCell = null;

// DOM Elements
const boardEl = document.getElementById('board');
const statusDisplay = document.getElementById('status-display');
const gameStatusLog = document.getElementById('game-status-log');
const chatLog = document.querySelector('.chat-log');

// CSRF Helper
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

function initGame(config) {
    gameId = config.gameId;
    boardState = config.boardState;
    currentTurn = config.currentTurn;
    status = config.status;
    playerSide = config.playerSide;
    // aiSide = config.aiSide;

    renderBoard();
    updateStatusUI();
}

function renderBoard() {
    boardEl.innerHTML = '';
    for (let r = 0; r < 10; r++) {
        for (let c = 0; c < 9; c++) {
            const cell = document.createElement('div');
            cell.className = 'cell';
            cell.dataset.row = r;
            cell.dataset.col = c;

            // Highlight logic
            if (selectedCell && selectedCell[0] === r && selectedCell[1] === c) {
                cell.classList.add('selected');
            }
            if (lastMove) {
                if ((lastMove.from[0] === r && lastMove.from[1] === c) ||
                    (lastMove.to[0] === r && lastMove.to[1] === c)) {
                    cell.classList.add('last-move');
                }
            }

            const pieceCode = boardState[r][c];
            if (pieceCode) {
                const img = document.createElement('img');
                img.src = `/static/games/pieces/${pieceCode}.svg`;
                img.className = 'piece';
                // Inline styles removed in favor of CSS
                cell.appendChild(img);
            }

            cell.onclick = () => handleCellClick(r, c);
            boardEl.appendChild(cell);
        }
    }
}

async function handleCellClick(r, c) {
    if (status !== 'ongoing') return;

    // Prevent moving out of turn
    // (Optional: let server reject it, but UI feedback is nice)
    // if (currentTurn !== playerSide) return;

    const pieceCode = boardState[r][c];
    const isMyPiece = pieceCode && pieceCode.startsWith(playerSide);

    if (selectedCell) {
        // Deselect if same cell
        if (selectedCell[0] === r && selectedCell[1] === c) {
            selectedCell = null;
            renderBoard();
            return;
        }

        // Select other piece of mine
        if (isMyPiece) {
            selectedCell = [r, c];
            renderBoard();
            return;
        }

        // Attempt move
        if (currentTurn !== playerSide) return; // Only allow move if it is my turn

        const moveData = {
            from: selectedCell,
            to: [r, c]
        };

        await sendMove(moveData);
        selectedCell = null;
    } else {
        // Select piece
        if (isMyPiece) {
            selectedCell = [r, c];
            renderBoard();
        }
    }
}

async function sendMove(move) {
    try {
        const res = await fetch(`/api/games/${gameId}/move`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRFToken': csrftoken
            },
            body: JSON.stringify(move)
        });

        const data = await res.json();
        if (data.ok) {
            updateGameState(data);
            logMove(move, "Player");

            if (data.status === 'ongoing' && data.current_turn !== playerSide) {
                // AI is thinking...
                startPolling();
            }
        } else {
            alert(`Error: ${data.message}`);
        }
    } catch (err) {
        console.error(err);
        alert("Server error");
    }
}

function updateGameState(data) {
    boardState = data.board_state;
    currentTurn = data.current_turn;
    status = data.status;
    lastMove = data.last_move;

    updateStatusUI();
    renderBoard();

    if (lastMove && currentTurn === playerSide) {
        // If it's now my turn, logging the LAST move means logging what just happened (AI move)
        logMove({ from: lastMove.from, to: lastMove.to }, "AI");
    }

    if (status === 'finished') {
        setTimeout(() => alert(`Game Over! Winner: ${data.winner}`), 100);
        logSystem(`Game Over. Winner: ${data.winner}`);
    }
}

function updateStatusUI() {
    if (statusDisplay) {
        let text = status === 'ongoing' ? "Playing" : "Finished";
        if (status === 'ongoing') {
            text += currentTurn === playerSide ? " (Your Turn)" : " (Thinking...)";
        }
        statusDisplay.innerText = text;
    }
    if (gameStatusLog) {
        // gameStatusLog.innerText = `Turn: ${currentTurn}`;
    }
}

function logMove(move, who) {
    if (!chatLog) return;
    const entry = document.createElement('div');
    entry.className = 'log-entry';
    // Simple coordinate log
    entry.innerText = `${who}: (${move.from}) → (${move.to})`;
    chatLog.appendChild(entry);
    chatLog.scrollTop = chatLog.scrollHeight;
}

function logSystem(msg) {
    if (!chatLog) return;
    const entry = document.createElement('div');
    entry.className = 'log-entry system';
    entry.innerText = `System: ${msg}`;
    chatLog.appendChild(entry);
    chatLog.scrollTop = chatLog.scrollHeight;
}

let pollInterval = null;

function startPolling() {
    if (pollInterval) clearInterval(pollInterval);
    updateStatusUI(); // Update to "Thinking..."

    pollInterval = setInterval(async () => {
        try {
            const res = await fetch(`/api/games/${gameId}/`);
            const data = await res.json();

            if (data.ok) {
                // Check if turn changed back to player OR game ended
                if (data.current_turn === playerSide || data.status === 'finished') {
                    clearInterval(pollInterval);
                    pollInterval = null;
                    updateGameState(data);
                }
            }
        } catch (err) {
            console.error("Polling error", err);
        }
    }, 1000);
}
