from django.db import models
import uuid

class Game(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    # State
    board_state = models.JSONField()  # 10x9 array
    current_turn = models.CharField(max_length=1, default='r')  # 'r' or 'b'
    status = models.CharField(max_length=20, default='ongoing')  # 'ongoing' | 'finished'
    
    # Settings
    player_side = models.CharField(max_length=1, default='r')
    ai_side = models.CharField(max_length=1, default='b')
    difficulty = models.CharField(max_length=20, default='normal')
    
    # Result
    winner = models.CharField(max_length=10, null=True, blank=True)  # 'r' | 'b' | 'draw'
    end_reason = models.CharField(max_length=50, null=True, blank=True)  # 'checkmate', 'resign', etc.
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Game {self.id} ({self.status})"

class Move(models.Model):
    game = models.ForeignKey(Game, on_delete=models.CASCADE, related_name='moves')
    ply = models.IntegerField(help_text="Move number (half-move)")
    side = models.CharField(max_length=1)  # 'r' | 'b'
    
    # From/To coordinates
    from_row = models.IntegerField()
    from_col = models.IntegerField()
    to_row = models.IntegerField()
    to_col = models.IntegerField()
    
    # Metadata
    piece = models.CharField(max_length=5)  # e.g. 'rP'
    captured = models.CharField(max_length=5, null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['ply']

    def __str__(self):
        return f"Move {self.ply}: {self.piece} {self.from_row},{self.from_col} -> {self.to_row},{self.to_col}"
