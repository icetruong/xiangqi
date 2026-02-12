# Xiangqi (Chinese Chess) Web Game

Play Chinese Chess against AI in your browser! 🎮

## 🎯 Features

- ♟️ Full Xiangqi game implementation
- 🤖 AI opponent with 3 difficulty levels
- 🎨 Beautiful modern UI with React
- 📱 Responsive design
- ⚡ Real-time game state updates
- ↩️ Undo functionality
- 🎯 Legal move highlighting

## 🏗️ Tech Stack

### Backend
- **FastAPI** - Modern Python web framework
- **Python 3.11+** - Game engine
- **Uvicorn** - ASGI server

### Frontend
- **React 18** - UI framework
- **Vite** - Build tool
- **Axios** - HTTP client
- **CSS3** - Modern styling with gradients and animations

## 📁 Project Structure

```
xiangqi/
├── backend/                 # FastAPI backend
│   ├── main.py              # API server
│   ├── requirements.txt     # Python dependencies
│   └── Dockerfile           # Docker config
├── frontend/                # React frontend
│   ├── src/
│   │   ├── components/      # React components
│   │   ├── App.jsx          # Main app
│   │   └── api.js           # API utilities
│   └── package.json
├── engine/                  # Game engine
│   ├── game.py              # Game logic
│   ├── board.py             # Board management
│   ├── ai/                  # AI algorithms
│   └── rules/               # Game rules
└── DEPLOYMENT.md            # Deployment guide
```

## 🚀 Quick Start

### Prerequisites
- Python 3.11+
- Node.js 18+
- npm or yarn

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd xiangqi
```

### 2. Run Backend
```bash
# Install dependencies
pip install -r backend/requirements.txt

# Start server
python -m uvicorn backend.main:app --reload
```
Backend runs on `http://localhost:8000`

### 3. Run Frontend
```bash
# Navigate to frontend
cd frontend

# Install dependencies
npm install

# Start dev server
npm run dev
```
Frontend runs on `http://localhost:5173`

### 4. Play!
Open your browser to `http://localhost:5173` and start playing!

## 🌐 Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions to:
- **Render** (Backend - Free tier available)
- **Vercel** (Frontend - Free)

## 🎮 How to Play

1. You play as **RED** (bottom)
2. AI plays as **BLACK** (top)
3. Click a piece to select it
4. Legal moves will be highlighted in green
5. Click destination to move
6. AI will automatically make its move
7. First to checkmate wins!

## 🎯 Difficulty Levels

- **Easy**: AI thinks 2 moves ahead
- **Medium**: AI thinks 3 moves ahead (default)
- **Hard**: AI thinks 4 moves ahead

## 📚 API Documentation

Backend API is documented with FastAPI's automatic docs:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## 🛠️ Development

### Backend Development
```bash
# Run with auto-reload
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Development
```bash
# Run with HMR (Hot Module Replacement)
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## 🧪 Testing

```bash
# Run backend tests
pytest tests/

# Test specific features
pytest tests/test_game.py
pytest tests/test_board.py
```

## 📝 License

This project is for educational purposes.

## 🤝 Credits

Game engine based on Chinese Chess (Xiangqi) rules.
Built as a student project for DUT Python course.

---

**Enjoy playing Xiangqi! 象棋 🎮**
