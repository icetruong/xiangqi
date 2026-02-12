import axios from 'axios';

// API base URL - change this to your deployed backend URL
const API_BASE_URL = 'http://localhost:8000';

const api = axios.create({
    baseURL: API_BASE_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

// API functions
export const gameAPI = {
    // Create new game
    createGame: async () => {
        const response = await api.post('/api/game/new');
        return response.data;
    },

    // Get game state
    getGameState: async (gameId) => {
        const response = await api.get(`/api/game/${gameId}`);
        return response.data;
    },

    // Make a move
    makeMove: async (gameId, src, dst) => {
        const response = await api.post(`/api/game/${gameId}/move`, {
            src,
            dst,
        });
        return response.data;
    },

    // AI makes a move
    aiMove: async (gameId, difficulty = 'medium') => {
        const response = await api.post(
            `/api/game/${gameId}/ai-move?difficulty=${difficulty}`
        );
        return response.data;
    },

    // Undo move
    undoMove: async (gameId) => {
        const response = await api.post(`/api/game/${gameId}/undo`);
        return response.data;
    },

    // Get legal moves for a piece
    getLegalMoves: async (gameId, row, col) => {
        const response = await api.get(
            `/api/game/${gameId}/legal-moves?row=${row}&col=${col}`
        );
        return response.data;
    },
};

export default api;
