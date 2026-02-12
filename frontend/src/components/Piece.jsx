import React from 'react';
import './Piece.css';

// Piece name mapping
const PIECE_NAMES = {
    rK: '帥', // Red King (General)
    rA: '仕', // Red Advisor
    rE: '相', // Red Elephant
    rR: '俥', // Red Rook (Chariot)
    rN: '傌', // Red Knight (Horse)
    rC: '炮', // Red Cannon
    rP: '兵', // Red Pawn (Soldier)

    bK: '將', // Black King
    bA: '士', // Black Advisor
    bE: '象', // Black Elephant
    bR: '車', // Black Rook
    bN: '馬', // Black Knight
    bC: '砲', // Black Cannon
    bP: '卒', // Black Pawn
};

const Piece = ({ piece }) => {
    if (!piece || piece === '.' || piece === '') return null;

    const color = piece[0]; // 'r' or 'b'
    const displayName = PIECE_NAMES[piece] || piece;

    return (
        <div className={`piece ${color === 'r' ? 'red' : 'black'}`}>
            <div className="piece-inner">
                {displayName}
            </div>
        </div>
    );
};

export default Piece;
