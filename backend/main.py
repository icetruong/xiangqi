"""
FastAPI Backend for Xiangqi Game
Provides REST API for game management and AI player
"""
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, List, Tuple, Optional
import uuid
from datetime import datetime

# Import game engine
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from engine.game import Game
from engine.enums import GameStatus

app = FastAPI(title="Xiangqi API", version="1.0.0")

# Configure CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory game storage (use Redis for production)
games: Dict[str, Game] = {}
game_metadata: Dict[str, dict] = {}


# Request/Response Models
class MoveRequest(BaseModel):
    src: Tuple[int, int]
    dst: Tuple[int, int]


class NewGameResponse(BaseModel):
    game_id: str
    board: List[List[str]]
    turn: str
    status: str


class GameStateResponse(BaseModel):
    game_id: str
    board: List[List[str]]
    turn: str
    status: str
    last_move: Optional[dict] = None


class MoveResponse(BaseModel):
    success: bool
    board: List[List[str]]
    turn: str
    status: str
    message: str
    move: Optional[dict] = None


class LegalMovesResponse(BaseModel):
    legal_moves: List[Tuple[int, int]]


# Helper functions
def serialize_board(game: Game) -> List[List[str]]:
    """Convert board to JSON-serializable format"""
    return [[cell for cell in row] for row in game.board.board]


def get_game(game_id: str) -> Game:
    """Get game by ID or raise 404"""
    if game_id not in games:
        raise HTTPException(status_code=404, detail="Game not found")
    return games[game_id]


# API Endpoints
@app.get("/")
def root():
    return {
        "message": "Xiangqi API",
        "version": "1.0.0",
        "endpoints": {
            "new_game": "POST /api/game/new",
            "get_state": "GET /api/game/{game_id}",
            "make_move": "POST /api/game/{game_id}/move",
            "ai_move": "POST /api/game/{game_id}/ai-move",
            "undo": "POST /api/game/{game_id}/undo",
            "legal_moves": "GET /api/game/{game_id}/legal-moves"
        }
    }


@app.post("/api/game/new", response_model=NewGameResponse)
def create_new_game():
    """Create a new game session"""
    game_id = str(uuid.uuid4())
    game = Game()
    
    games[game_id] = game
    game_metadata[game_id] = {
        "created_at": datetime.now().isoformat(),
        "moves_count": 0
    }
    
    return NewGameResponse(
        game_id=game_id,
        board=serialize_board(game),
        turn=game.get_turn(),
        status=game.get_status()
    )


@app.get("/api/game/{game_id}", response_model=GameStateResponse)
def get_game_state(game_id: str):
    """Get current game state"""
    game = get_game(game_id)
    
    last_move = None
    if game.history:
        last = game.history[-1]
        last_move = {
            "src": last.src,
            "dst": last.dst,
            "moved": last.moved,
            "captured": last.captured
        }
    
    return GameStateResponse(
        game_id=game_id,
        board=serialize_board(game),
        turn=game.get_turn(),
        status=game.get_status(),
        last_move=last_move
    )


@app.post("/api/game/{game_id}/move", response_model=MoveResponse)
def make_move(game_id: str, move: MoveRequest):
    """Player makes a move"""
    game = get_game(game_id)
    
    # Check if game is over
    if game.get_status() in ["checkmate", "stalemate"]:
        raise HTTPException(status_code=400, detail="Game is already over")
    
    # Try to make the move
    success = game.make_move(move.src, move.dst)
    
    if success:
        game_metadata[game_id]["moves_count"] += 1
        message = "Move successful"
        
        # Check game status
        status = game.get_status()
        if status == "checkmate":
            message = "Checkmate! Game over."
        elif status == "check":
            message = "Check!"
        elif status == "stalemate":
            message = "Stalemate! Game over."
            
        return MoveResponse(
            success=True,
            board=serialize_board(game),
            turn=game.get_turn(),
            status=status,
            message=message,
            move={"src": move.src, "dst": move.dst}
        )
    else:
        return MoveResponse(
            success=False,
            board=serialize_board(game),
            turn=game.get_turn(),
            status=game.get_status(),
            message="Invalid move"
        )


@app.post("/api/game/{game_id}/ai-move", response_model=MoveResponse)
def ai_move(game_id: str, difficulty: str = "medium"):
    """AI makes a move"""
    game = get_game(game_id)
    
    # Check if game is over
    if game.get_status() in ["checkmate", "stalemate"]:
        raise HTTPException(status_code=400, detail="Game is already over")
    
    # Set AI difficulty
    depth_map = {
        "easy": 2,
        "medium": 3,
        "hard": 4
    }
    depth = depth_map.get(difficulty, 3)
    
    # AI makes move
    try:
        success = game.ai_move_minimax(depth=depth)
        
        if success:
            game_metadata[game_id]["moves_count"] += 1
            last_move = game.history[-1]
            
            message = "AI moved"
            status = game.get_status()
            if status == "checkmate":
                message = "AI wins! Checkmate."
            elif status == "check":
                message = "AI moved. You are in check!"
            elif status == "stalemate":
                message = "Stalemate! Game over."
            
            return MoveResponse(
                success=True,
                board=serialize_board(game),
                turn=game.get_turn(),
                status=status,
                message=message,
                move={
                    "src": last_move.src,
                    "dst": last_move.dst,
                    "captured": last_move.captured
                }
            )
        else:
            raise HTTPException(status_code=500, detail="AI could not find a valid move")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI error: {str(e)}")


@app.post("/api/game/{game_id}/undo")
def undo_move(game_id: str):
    """Undo last move"""
    game = get_game(game_id)
    
    success = game.undo()
    
    if success:
        game_metadata[game_id]["moves_count"] = max(0, game_metadata[game_id]["moves_count"] - 1)
        return {
            "success": True,
            "board": serialize_board(game),
            "turn": game.get_turn(),
            "status": game.get_status(),
            "message": "Move undone"
        }
    else:
        return {
            "success": False,
            "message": "No moves to undo"
        }


@app.get("/api/game/{game_id}/legal-moves", response_model=LegalMovesResponse)
def get_legal_moves(game_id: str, row: int, col: int):
    """Get legal moves for a piece at given position"""
    game = get_game(game_id)
    
    from engine.rules.game_rules import generate_legal_moves
    
    # Get all legal moves for current player
    all_moves = generate_legal_moves(game.board, game.get_turn())
    
    # Filter moves that start from the given position
    legal_destinations = [
        (dst[0], dst[1]) 
        for src, dst in all_moves 
        if src[0] == row and src[1] == col
    ]
    
    return LegalMovesResponse(legal_moves=legal_destinations)


@app.delete("/api/game/{game_id}")
def delete_game(game_id: str):
    """Delete a game session"""
    if game_id in games:
        del games[game_id]
        del game_metadata[game_id]
        return {"success": True, "message": "Game deleted"}
    else:
        raise HTTPException(status_code=404, detail="Game not found")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
