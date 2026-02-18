// ──────────────────────────────────────────────
//  constants.js — Board dimensions & piece names
// ──────────────────────────────────────────────

// ── Piece Name Mapping ──
var PIECE_NAMES = {
    rK: '\u5E25', rA: '\u4ED5', rE: '\u76F8', rN: '傌', rH: '傌', rR: '俥', rC: '炮', rP: '\u5175',
    bK: '\u5C07', bA: '\u58EB', bE: '\u8C61', bN: '\u99AC', bH: '\u99AC', bR: '\u8ECA', bC: '\u7832', bP: '\u5352'
};

// ── Board Constants ──
var COLS = 9;
var ROWS = 10;
var CELL_SIZE = 64;
var BOARD_PAD = 32;
var BOARD_W = (COLS - 1) * CELL_SIZE;   // 512
var BOARD_H = (ROWS - 1) * CELL_SIZE;   // 576
var PIECE_SIZE = Math.round(CELL_SIZE * 0.82);
var HINT_SIZE = 14;
var FONT_SIZE = Math.round(PIECE_SIZE * 0.58);

// ── SVG namespace ──
var SVG_NS = 'http://www.w3.org/2000/svg';
