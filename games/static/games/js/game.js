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
const statusEl = document.getElementById('status');
const turnEl = document.getElementById('turn');

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
                    cell.style.backgroundColor = "rgba(255, 255, 0, 0.2)";
                }
            }

            const pieceCode = boardState[r][c];
            if (pieceCode) {
                const img = document.createElement('img');
                img.src = `/static/games/pieces/${pieceCode}.svg`;
                img.className = 'piece';
                img.style.width = '50px';
                img.style.height = '50px';
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
            boardState = data.board_state;
            currentTurn = data.current_turn;
            status = data.status;
            statusEl.innerText = status;
            turnEl.innerText = currentTurn;
            lastMove = data.last_move;

            renderBoard();

            if (status === 'finished') {
                setTimeout(() => alert(`Game Over! Winner: ${data.winner}`), 100);
            }
        } else {
            alert(`Error: ${data.message}`);
        }
    } catch (err) {
        console.error(err);
        alert("Server error");
    }
}
