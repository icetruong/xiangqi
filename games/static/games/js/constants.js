// ──────────────────────────────────────────────
//  constants.js — Board dimensions & piece names
// ──────────────────────────────────────────────

var PIECE_NAMES = {
    rK: '帥', rA: '仕', rE: '相', rN: '傌', rH: '傌', rR: '俥', rC: '炮', rP: '兵',
    bK: '將', bA: '士', bE: '象', bN: '馬', bH: '馬', bR: '車', bC: '砲', bP: '卒'
};

// ── Board Topology ──
var COLS = 9;
var ROWS = 10;

// ── SVG ViewBox ──
var VB_W = 900;
var VB_H = 1000;
var MARGIN_X = 90;
var MARGIN_Y = 90;

// ── Grid (viewBox units) ──
var GRID_W = VB_W - 2 * MARGIN_X;       // 720
var GRID_H = VB_H - 2 * MARGIN_Y;       // 820
var CELL_W = GRID_W / (COLS - 1);        // 90
var CELL_H = GRID_H / (ROWS - 1);       // ~91.11

// ── Coordinate helpers ──
function ix(c) { return MARGIN_X + c * CELL_W; }
function iy(r) { return MARGIN_Y + r * CELL_H; }

// ── Piece sizing (viewBox units, Step 3+) ──
var PIECE_SIZE = Math.round(CELL_W * 0.82);
var FONT_SIZE = Math.round(PIECE_SIZE * 0.58);
var HINT_SIZE = 14;

var SVG_NS = 'http://www.w3.org/2000/svg';
