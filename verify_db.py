import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "xiangqi_project.settings")
django.setup()

from games.models import Game

def verify():
    try:
        g = Game.objects.create(board_state=[[""]*9]*10)
        print(f"Successfully created game: {g}")
        count = Game.objects.count()
        print(f"Total games: {count}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    verify()
