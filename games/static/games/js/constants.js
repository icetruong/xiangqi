// ──────────────────────────────────────────────
//  constants.js — Board topology & piece names
// ──────────────────────────────────────────────

var PIECE_NAMES = {
    rK: '帥', rA: '仕', rE: '相', rN: '傌', rR: '俥', rC: '炮', rP: '兵',
    bK: '將', bA: '士', bE: '象', bN: '馬', bR: '車', bC: '砲', bP: '卒'
};

var COLS = 9;   // intersections wide
var ROWS = 10;  // intersections tall
var SVG_NS = 'http://www.w3.org/2000/svg';

// Debug: set true to show dot at every intersection
var DEBUG_GRID = false;
