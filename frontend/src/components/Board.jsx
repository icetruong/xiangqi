import React from 'react';
import Piece from './Piece';
import './Board.css';

const Board = ({ board, onSquareClick, selectedSquare, legalMoves, lastMove, isDisabled }) => {
    const isSelected = (row, col) => {
        return selectedSquare && selectedSquare[0] === row && selectedSquare[1] === col;
    };

    const isLegalMove = (row, col) => {
        return legalMoves.some((move) => move[0] === row && move[1] === col);
    };

    const isLastMove = (row, col) => {
        if (!lastMove) return false;
        return (
            (lastMove.src[0] === row && lastMove.src[1] === col) ||
            (lastMove.dst[0] === row && lastMove.dst[1] === col)
        );
    };

    if (!board || board.length === 0) {
        return <div className="board loading">Loading board...</div>;
    }

    return (
        <div className="board-container">
            <div className="board">
                {board.map((row, rowIndex) => (
                    <div key={rowIndex} className="board-row">
                        {row.map((cell, colIndex) => {
                            const squareClass = `square ${isSelected(rowIndex, colIndex) ? 'selected' : ''} ${isLegalMove(rowIndex, colIndex) ? 'legal-move' : ''
                                } ${isLastMove(rowIndex, colIndex) ? 'last-move' : ''}`;

                            return (
                                <div
                                    key={`${rowIndex}-${colIndex}`}
                                    className={squareClass}
                                    onClick={() => !isDisabled && onSquareClick(rowIndex, colIndex)}
                                    style={{ cursor: isDisabled ? 'not-allowed' : 'pointer' }}
                                >
                                    {/* River text */}
                                    {rowIndex === 4 && colIndex < 4 && (
                                        <div className="river-text">楚河</div>
                                    )}
                                    {rowIndex === 5 && colIndex > 4 && (
                                        <div className="river-text">漢界</div>
                                    )}

                                    {/* Grid lines */}
                                    <div className="grid-lines"></div>

                                    {/* Piece */}
                                    {cell && cell !== '.' && <Piece piece={cell} />}

                                    {/* Legal move indicator */}
                                    {isLegalMove(rowIndex, colIndex) && (
                                        <div className="move-indicator"></div>
                                    )}
                                </div>
                            );
                        })}
                    </div>
                ))}
            </div>
        </div>
    );
};

export default Board;
