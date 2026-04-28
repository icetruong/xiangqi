from dataclasses import dataclass

@dataclass(slots=True)
class Move:
    src: int
    dst: int
    moved: int
    captured: int