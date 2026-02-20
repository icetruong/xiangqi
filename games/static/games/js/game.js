// ──────────────────────────────────────────────
//  game.js — Entry point (Step 4)
//  Load order: constants → svg-grid →
//  piece-renderer → game-logic → game
// ──────────────────────────────────────────────

// ── Game state ──
var gameId = null;
var boardState = [];
var currentTurn = '';
var status = '';
var playerSide = '';
var aiSide = '';
var lastMove = null;
var legalMoves = [];

// ── DOM ──
var boardEl = document.getElementById('board');

// ── Init ──
function initGame(config) {
    gameId = config.gameId;
    boardState = config.boardState;
    currentTurn = config.currentTurn;
    status = config.status;
    playerSide = config.playerSide;
    aiSide = config.aiSide;
    legalMoves = config.legalMoves || [];
    lastMove = config.lastMove || null;

    // Layer 2: SVG grid
    initBoardStructure();

    // Layer 3: markers (above SVG, below pieces)
    initMarkersLayer();

    // Render pieces after first paint (bounding box ready)
    requestAnimationFrame(function () {
        renderBoard(false);

        // Enable clicks (Step 4)
        enablePieceClicks();

        // If it's AI turn on load, start polling immediately
        if (status === 'ongoing' && currentTurn !== playerSide) {
            isLocked = true;
            startPolling();
        }
    });
}
