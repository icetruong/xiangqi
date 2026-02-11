# Color, PieceType, GameStatus

from enum import Enum

class Color(str, Enum):
    RED = "r"
    BLACK = "b"

    def opposite(self) -> "Color":
        return Color.RED if self == Color.BLACK else Color.BLACK
    
class PieceType(str, Enum):
    ROOK = "R"      # Xe
    KNIGHT = "N"    # Mã
    ELEPHANT = "E"  # Tượng
    ADVISOR = "A"   # Sĩ
    KING = "K"      # Tướng
    CANNON = "C"    # Pháo
    PAWN = "P"      # Tốt

class GameStatus(str, Enum):
    ONGOING = "ONGOING"
    CHECK = "CHECK"
    CHECKMATE = "CHECKMATE"
    STALEMATE = "STALEMATE"
