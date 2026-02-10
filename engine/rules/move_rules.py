# Luật đi cơ bản của quân
from typing import List, Tuple
from engine.board import Board
from engine.utils.position import EMPTY, color_of, same_color, is_empty, type_of

def rook_moves(board: Board, src: Tuple[int, int]) -> List[Tuple[int, int]]:
    sr, sc = src
    piece = board.get(sr, sc)

    if is_empty(piece) or type_of(piece) != "R":
        return []
    
    moves: List[Tuple[int, int]] = []
    my_color = color_of(piece)

    directions = [(-1,0), (1,0), (0,-1), (0,1)]
    for dr, dc in directions:
        rook_r = dr+sr
        rook_c = dc+sc
        while board.in_bounds(rook_r, rook_c):
            target = board.get(rook_r, rook_c)
            if is_empty(target):
                moves.append((rook_r, rook_c))
            else:
                if not same_color(piece, target):
                    moves.append((rook_r, rook_c))
                break

            rook_r+=dr
            rook_c+=dc

    return moves

def knight_moves(board: Board, src: Tuple[int, int]) -> List[Tuple[int, int]]:
    sr, sc = src
    piece = board.get(sr, sc)

    if is_empty(piece) or type_of(piece) != "N":
        return []
    
    moves: List[Tuple[int, int]] = []
    my_color = color_of(piece)

    offsets = [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,1),(2,-1)]
    for dr, dc in offsets:
        knight_r = dr+sr
        knight_c = dc+sc
        if board.in_bounds(knight_r, knight_c):
            target = board.get(knight_r, knight_c)
            obstacle_r: int = 0
            obstacle_c: int = 0
            if abs(dr) == 2:
                obstacle_r, obstacle_c = sr + dr//2, sc
            else:
                obstacle_r, obstacle_c = sr , sc + dc//2
            obstacle = board.get(obstacle_r, obstacle_c)
            if is_empty(obstacle):
                if is_empty(target) or not same_color(piece, target):
                    moves.append((knight_r, knight_c))

    return moves

def cannon_moves(board: Board, src: Tuple[int, int]) -> List[Tuple[int, int]]:
    sr, sc = src
    piece = board.get(sr, sc)

    if is_empty(piece) or type_of(piece) != "C":
        return []
    
    moves: List[Tuple[int, int]] = []
    my_color = color_of(piece)
    directions = [(-1,0), (1,0), (0,-1), (0,1)]

    for dr, dc in directions:
        cannon_r = dr + sr
        cannon_c = dc + sc
        jump = False
        while board.in_bounds(cannon_r, cannon_c):
            target = board.get(cannon_r, cannon_c)
            if not jump:
                if is_empty(target):
                    moves.append((cannon_r, cannon_c))
                else:
                    jump = True
            else:
                if not is_empty(target):
                    if not same_color(piece, target):
                        moves.append((cannon_r, cannon_c))
                    break 
            cannon_r+= dr
            cannon_c+= dc

    return moves

def elephant_moves(board: Board, src: Tuple[int, int]) -> List[Tuple[int, int]]:
    sr, sc = src
    piece = board.get(sr, sc)

    if is_empty(piece) or type_of(piece) != "E":
        return []
    
    moves: List[Tuple[int, int]] = []
    my_color = color_of(piece)
    
    offsets = [(-2,-2),(-2,2),(2,-2),(2,2)]
    for dr, dc in offsets:
        elephant_r = dr + sr
        elephant_c = dc + sc
        if my_color == "b" and elephant_r > 4:
            continue
        if my_color == "r" and elephant_r < 5:
            continue
        if board.in_bounds(elephant_r, elephant_c):
            target = board.get(elephant_r, elephant_c)
            obstacle_r = sr + dr//2
            obstacle_c = sc + dc//2
            obstacle = board.get(obstacle_r, obstacle_c)
            if is_empty(obstacle):
                if is_empty(target) or not same_color(piece, target):
                    moves.append((elephant_r, elephant_c))

    return moves

def pawn_moves(board: Board, src: Tuple[int, int]) -> List[Tuple[int, int]]:
    sr, sc = src
    piece = board.get(sr, sc)

    if is_empty(piece) or type_of(piece) != "P":
        return []
    
    moves: List[Tuple[int, int]] = []
    my_color = color_of(piece)
    offsets = [(-1,0)] if my_color == "r" else [(1,0)]
    if (my_color == "b" and sr > 4) or (my_color == "r" and sr < 5):
        offsets += [(0,-1), (0,1)]
     
    for dr, dc in offsets:
        pawn_r = dr+sr
        pawn_c = dc+sc
        if board.in_bounds(pawn_r, pawn_c):
            target = board.get(pawn_r, pawn_c)
            if is_empty(target) or not same_color(piece, target):
                moves.append((pawn_r, pawn_c))

    return moves

def advisor_moves(board: Board, src: Tuple[int, int]) -> List[Tuple[int, int]]:
    sr, sc = src
    piece = board.get(sr, sc)

    if is_empty(piece) or type_of(piece) != "A":
        return []
    
    moves: List[Tuple[int, int]] = []
    my_color = color_of(piece)

    offsets = [(-1,-1),(-1,1),(1,-1),(1,1)]

    for dr, dc in offsets:
        advisor_r = dr+sr
        advisor_c = dc+sc
        if board.in_palace(advisor_r, advisor_c, my_color):
            target = board.get(advisor_r, advisor_c)
            if is_empty(target) or not same_color(piece, target):
                moves.append((advisor_r, advisor_c))

    return moves

def king_moves(board: Board, src: Tuple[int, int]) -> List[Tuple[int, int]]:
    sr, sc = src
    piece = board.get(sr, sc)

    if is_empty(piece) or type_of(piece) != "K":
        return []
    
    moves: List[Tuple[int, int]] = []
    my_color = color_of(piece)

    offsets = [(-1,0),(1,0),(0,-1),(0,1)]

    for dr, dc in offsets:
        king_r = dr+sr
        king_c = dc+sc
        if board.in_palace(king_r, king_c, my_color):
            target = board.get(king_r, king_c)
            if is_empty(target) or not same_color(piece, target):
                moves.append((king_r, king_c))

    return moves

def is_legal_basic_move(board: Board, src: Tuple[int, int], dst: Tuple[int, int]) -> bool:
    sr, sc = src
    piece = board.get(sr, sc)

    if is_empty(piece):
        return False
    
    if type_of(piece) == "R":
        return dst in rook_moves(board=board, src=src)
    if type_of(piece) == "N":
        return dst in knight_moves(board=board, src=src)
    if type_of(piece) == "C":
        return dst in cannon_moves(board=board, src=src)
    if type_of(piece) == "E":
        return dst in elephant_moves(board=board, src=src)
    if type_of(piece) == "P":
        return dst in pawn_moves(board=board, src=src)
    if type_of(piece) == "A":
        return dst in advisor_moves(board=board, src=src)
    if type_of(piece) == "K":
        return dst in king_moves(board=board, src=src)