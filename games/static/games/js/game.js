// ──────────────────────────────────────────────
//  game.js — Entry point
//  Loads after: constants.js, svg-grid.js,
//  piece-renderer.js, game-logic.js
// ──────────────────────────────────────────────

// ── Game State ──
var gameId = null;
var boardState = [];
var currentTurn = '';
var status = '';
var playerSide = '';
var aiSide = '';
var lastMove = null;
var selectedCell = null;
var legalMoves = [];
var isAnimating = false;

// ── DOM ──
var boardEl = document.getElementById('board');
var statusDisplay = document.getElementById('status-display');
var gameStatusLog = document.getElementById('game-status-log');
var chatLog = document.querySelector('.chat-log');

// ── Board Click (Step 3+) ──
// boardEl.addEventListener('click', function (e) {
//     if (isAnimating) return;
//     var rect = boardEl.getBoundingClientRect();
//     var x = e.clientX - rect.left;
//     var y = e.clientY - rect.top;
//     var c = Math.round((x - BOARD_PAD) / CELL_SIZE);
//     var r = Math.round((y - BOARD_PAD) / CELL_SIZE);
//     if (c >= 0 && c < COLS && r >= 0 && r < ROWS) {
//         handleCellClick(r, c);
//     }
// });

// ── Init ──
function initGame(config) {
    gameId = config.gameId;
    boardState = config.boardState;
    currentTurn = config.currentTurn;
    status = config.status;
    playerSide = config.playerSide;
    legalMoves = config.legalMoves || [];
    lastMove = config.lastMove || null;

    // Step 2: Grid only
    initBoardStructure();

    // Step 3+: Pieces & game logic (uncomment later)
    // renderBoard(false);
    // updateStatusUI();
}
