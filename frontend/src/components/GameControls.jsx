import React from 'react';
import './GameControls.css';

const GameControls = ({ onNewGame, onUndo, difficulty, onDifficultyChange, isDisabled }) => {
    return (
        <div className="game-controls">
            <h2>Controls</h2>

            <div className="control-section">
                <h3>Difficulty</h3>
                <div className="difficulty-buttons">
                    <button
                        className={`btn-difficulty ${difficulty === 'easy' ? 'active' : ''}`}
                        onClick={() => onDifficultyChange('easy')}
                        disabled={isDisabled}
                    >
                        Easy
                    </button>
                    <button
                        className={`btn-difficulty ${difficulty === 'medium' ? 'active' : ''}`}
                        onClick={() => onDifficultyChange('medium')}
                        disabled={isDisabled}
                    >
                        Medium
                    </button>
                    <button
                        className={`btn-difficulty ${difficulty === 'hard' ? 'active' : ''}`}
                        onClick={() => onDifficultyChange('hard')}
                        disabled={isDisabled}
                    >
                        Hard
                    </button>
                </div>
            </div>

            <div className="control-section">
                <h3>Actions</h3>
                <button className="btn-action btn-new" onClick={onNewGame} disabled={isDisabled}>
                    🎮 New Game
                </button>
                <button className="btn-action btn-undo" onClick={onUndo} disabled={isDisabled}>
                    ↩️ Undo
                </button>
            </div>

            <div className="control-section">
                <h3>How to Play</h3>
                <div className="instructions">
                    <p>🔴 You are RED (bottom)</p>
                    <p>⚫ AI is BLACK (top)</p>
                    <p>• Click piece to select</p>
                    <p>• Click destination to move</p>
                    <p>• Green dots = legal moves</p>
                </div>
            </div>
        </div>
    );
};

export default GameControls;
