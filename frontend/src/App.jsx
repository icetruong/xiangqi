import { useState, useEffect } from 'react';
import { gameAPI } from './api';
import Board from './components/Board';
import GameControls from './components/GameControls';
import StatusPanel from './components/StatusPanel';
import './App.css';

function App() {
    const [gameId, setGameId] = useState(null);
    const [board, setBoard] = useState([]);
    const [turn, setTurn] = useState('');
    const [status, setStatus] = useState('');
    const [selectedSquare, setSelectedSquare] = useState(null);
    const [legalMoves, setLegalMoves] = useState([]);
    const [isAiThinking, setIsAiThinking] = useState(false);
    const [difficulty, setDifficulty] = useState('medium');
    const [message, setMessage] = useState('');
    const [lastMove, setLastMove] = useState(null);

    // Create new game on mount
    useEffect(() => {
        createNewGame();
    }, []);

    // Auto AI move when it's black's turn
    useEffect(() => {
        if (turn === 'b' && status === 'ongoing' && gameId && !isAiThinking) {
            triggerAiMove();
        }
    }, [turn, status, gameId]);

    const createNewGame = async () => {
        try {
            const data = await gameAPI.createGame();
            setGameId(data.game_id);
            setBoard(data.board);
            setTurn(data.turn);
            setStatus(data.status);
            setSelectedSquare(null);
            setLegalMoves([]);
            setMessage('New game started! You are RED. Make your move.');
            setLastMove(null);
        } catch (error) {
            console.error('Error creating game:', error);
            setMessage('Error creating game. Make sure backend is running!');
        }
    };

    const handleSquareClick = async (row, col) => {
        if (isAiThinking || status !== 'ongoing') return;
        if (turn !== 'r') return; // Only allow moves on player's turn

        const clickedPiece = board[row][col];

        // If clicking on own piece, select it
        if (clickedPiece && clickedPiece[0] === 'r') {
            setSelectedSquare([row, col]);
            try {
                const data = await gameAPI.getLegalMoves(gameId, row, col);
                setLegalMoves(data.legal_moves);
            } catch (error) {
                console.error('Error getting legal moves:', error);
                setLegalMoves([]);
            }
        }
        // If a piece is selected and clicking on a legal move, make the move
        else if (
            selectedSquare &&
            legalMoves.some((move) => move[0] === row && move[1] === col)
        ) {
            await makeMove(selectedSquare, [row, col]);
        }
        // Otherwise, deselect
        else {
            setSelectedSquare(null);
            setLegalMoves([]);
        }
    };

    const makeMove = async (src, dst) => {
        try {
            const data = await gameAPI.makeMove(gameId, src, dst);
            if (data.success) {
                setBoard(data.board);
                setTurn(data.turn);
                setStatus(data.status);
                setMessage(data.message);
                setSelectedSquare(null);
                setLegalMoves([]);
                setLastMove({ src, dst });
            } else {
                setMessage(data.message);
            }
        } catch (error) {
            console.error('Error making move:', error);
            setMessage('Error making move');
        }
    };

    const triggerAiMove = async () => {
        setIsAiThinking(true);
        setMessage('AI is thinking...');
        try {
            const data = await gameAPI.aiMove(gameId, difficulty);
            if (data.success) {
                setBoard(data.board);
                setTurn(data.turn);
                setStatus(data.status);
                setMessage(data.message);
                setLastMove({ src: data.move.src, dst: data.move.dst });
            } else {
                setMessage('AI failed to move');
            }
        } catch (error) {
            console.error('Error with AI move:', error);
            setMessage('Error with AI move');
        } finally {
            setIsAiThinking(false);
        }
    };

    const handleUndo = async () => {
        if (isAiThinking) return;
        try {
            const data = await gameAPI.undoMove(gameId);
            if (data.success) {
                // Undo twice to undo both AI and player move
                const data2 = await gameAPI.undoMove(gameId);
                if (data2.success) {
                    setBoard(data2.board);
                    setTurn(data2.turn);
                    setStatus(data2.status);
                    setMessage('Undone');
                    setSelectedSquare(null);
                    setLegalMoves([]);
                    setLastMove(null);
                }
            } else {
                setMessage(data.message);
            }
        } catch (error) {
            console.error('Error undoing:', error);
        }
    };

    return (
        <div className="app">
            <div className="app-header">
                <h1>象棋 Xiangqi</h1>
                <p className="subtitle">Chinese Chess - Play against AI</p>
            </div>

            <div className="game-container">
                <StatusPanel
                    turn={turn}
                    status={status}
                    message={message}
                    isAiThinking={isAiThinking}
                />

                <Board
                    board={board}
                    onSquareClick={handleSquareClick}
                    selectedSquare={selectedSquare}
                    legalMoves={legalMoves}
                    lastMove={lastMove}
                    isDisabled={isAiThinking || status !== 'ongoing'}
                />

                <GameControls
                    onNewGame={createNewGame}
                    onUndo={handleUndo}
                    difficulty={difficulty}
                    onDifficultyChange={setDifficulty}
                    isDisabled={isAiThinking}
                />
            </div>
        </div>
    );
}

export default App;
