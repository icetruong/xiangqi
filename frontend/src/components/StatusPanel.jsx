import React from 'react';
import './StatusPanel.css';

const StatusPanel = ({ turn, status, message, isAiThinking }) => {
    const getTurnText = () => {
        if (turn === 'r') return '🔴 Your Turn (RED)';
        if (turn === 'b') return '⚫ AI Turn (BLACK)';
        return 'Starting...';
    };

    const getStatusClass = () => {
        if (status === 'checkmate') return 'status-checkmate';
        if (status === 'check') return 'status-check';
        if (status === 'stalemate') return 'status-stalemate';
        return 'status-ongoing';
    };

    const getStatusText = () => {
        if (status === 'checkmate') return '👑 Checkmate!';
        if (status === 'check') return '⚠️ Check!';
        if (status === 'stalemate') return '🤝 Stalemate';
        return '♟️ Game In Progress';
    };

    return (
        <div className="status-panel">
            <h2>Game Status</h2>

            <div className="status-item">
                <h3>Turn</h3>
                <div className={`status-value ${turn === 'r' ? 'player-turn' : 'ai-turn'}`}>
                    {getTurnText()}
                </div>
            </div>

            <div className="status-item">
                <h3>Status</h3>
                <div className={`status-value ${getStatusClass()}`}>
                    {getStatusText()}
                </div>
            </div>

            <div className="status-item">
                <h3>Message</h3>
                <div className="message-box">
                    {isAiThinking && (
                        <div className="ai-thinking">
                            <div className="spinner"></div>
                            <span>AI is thinking...</span>
                        </div>
                    )}
                    {!isAiThinking && <p>{message || 'Ready to play!'}</p>}
                </div>
            </div>

            <div className="status-item">
                <h3>Legend</h3>
                <div className="legend">
                    <div className="legend-item">
                        <div className="legend-color selected"></div>
                        <span>Selected Piece</span>
                    </div>
                    <div className="legend-item">
                        <div className="legend-color legal"></div>
                        <span>Legal Move</span>
                    </div>
                    <div className="legend-item">
                        <div className="legend-color last"></div>
                        <span>Last Move</span>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default StatusPanel;
