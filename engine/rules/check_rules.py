# Chiếu, chiếu bí
from typing import Tuple, Optional
from engine.board import Board
from engine.utils.position import is_empty, color_of, type_of

def find_king(board: Board, color: str) -> Optional[Tuple[int, int]]:
    return board.red_king if color == 'r' else board.black_king

def rook_attacks(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    kr, kc = dst
    if sr != kr and sc != kc:
        return False

    if sr == kr:
        step = 1 if sc < kc else -1
        for cc in range(sc + step, kc, step):
            if not is_empty(board.get(sr, cc)):
                return False
    elif sc == kc:
        step = 1 if sr < kr else -1
        for rr in range(sr + step, kr, step):
            if not is_empty(board.get(rr, sc)):
                return False
        
    return True

def cannon_attacks(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    kr, kc = dst
    if sr != kr and sc != kc:
        return False

    # đếm quân cản đường
    count = 0

    if sr == kr:
        step = 1 if sc < kc else -1
        for cc in range(sc + step, kc, step):
            if not is_empty(board.get(sr, cc)):
                count += 1
    elif sc == kc:
        step = 1 if sr < kr else -1
        for rr in range(sr + step, kr, step):
            if not is_empty(board.get(rr, sc)):
                count += 1
        
    return count == 1

def knight_attacks(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    kr, kc = dst
    offsets = [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,1),(2,-1)]

    for dr, dc in offsets:
        nr, nc = sr + dr, sc + dc
        obstacle_r: int = sr
        obstacle_c: int = sc
        if abs(dr) == 2:
            obstacle_r = sr + dr // 2
        elif abs(dc) == 2:
            obstacle_c = sc + dc // 2
        if (nr, nc) == dst:
            return is_empty(board.get(obstacle_r, obstacle_c))
    return False

def pawn_attacks(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    kr, kc = dst
    if color_of(board.get(sr, sc)) == "b":
        if sr <= 4:
            return False
        else:
            if sr == kr and abs(sc - kc) == 1:
                return True
            elif kr - sr == 1 and sc == kc:
                return True
            else:
                return False     
    if color_of(board.get(sr, sc)) == "r":
        if sr >= 5:
            return False
        else:
            if sr == kr and abs(sc - kc) == 1:
                return True
            elif sr - kr == 1 and sc == kc:
                return True
            else:
                return False 

    return False

            

def attacks_square(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    piece = board.get(sr, sc)
    if is_empty(piece):
        return False
    
    t = type_of(piece)
    if t == "R":
        return rook_attacks(board, src, dst)
    if t == "C":
        return cannon_attacks(board, src, dst)
    if t == "P":
        return pawn_attacks(board, src, dst)
    if t == "N":
        return knight_attacks(board, src, dst)
    return False

# check vua có bị chiếu không
def is_in_check(board: Board, color: str) -> bool:
    king_pos = find_king(board=board, color=color)
    if king_pos is None:
        return False  
    enemy = "r" if color == "b" else "b"
    for i in range(Board.ROWS):
        for j in range(Board.COLS):
            piece = board.get(i, j)
            if is_empty(piece):
                continue
            if color_of(piece) != enemy:
                continue

            if attacks_square(board=board, src=(i,j), dst=king_pos):
                return True
    return False
