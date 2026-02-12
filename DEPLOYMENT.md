# Xiangqi Game Deployment Guide

## 🚀 Quick Start (Local Testing)

### Backend
```bash
# Navigate to project root
cd d:\TaiLieuNam3_DUT\HKII\Python\xiangqi

# Install backend dependencies
pip install -r backend/requirements.txt

# Run backend server
python -m uvicorn backend.main:app --reload

# Backend will run on: http://localhost:8000
```

### Frontend
```bash
# Navigate to frontend folder
cd frontend

# Install dependencies
npm install

# Run development server
npm run dev

# Frontend will run on: http://localhost:5173
```

Now open your browser to `http://localhost:5173` and start playing! 🎮

---

## 🌐 Deploy to Internet (FREE)

### Step 1: Deploy Backend to Render

1. **Create Render Account**
   - Go to [render.com](https://render.com)
   - Sign up with GitHub

2. **Connect GitHub Repository**
   - Push your code to GitHub first:
     ```bash
     git init
     git add .
     git commit -m "Xiangqi game"
     git branch -M main
     git remote add origin https://github.com/YOUR_USERNAME/xiangqi.git
     git push -u origin main
     ```

3. **Create Web Service on Render**
   - Click "New +" → "Web Service"
   - Connect your GitHub repo
   - Configure:
     - **Name**: `xiangqi-backend`
     - **Environment**: Python 3
     - **Build Command**: `pip install -r backend/requirements.txt`
     - **Start Command**: `uvicorn backend.main:app --host 0.0.0.0 --port $PORT`
     - **Root Directory**: Leave blank
   - Click "Create Web Service"

4. **Get Backend URL**
   - After deployment, copy the URL (e.g., `https://xiangqi-backend.onrender.com`)

### Step 2: Deploy Frontend to Vercel

1. **Update API URL**
   - Edit `frontend/src/api.js`
   - Change `API_BASE_URL` to your Render backend URL:
     ```javascript
     const API_BASE_URL = 'https://xiangqi-backend.onrender.com';
     ```

2. **Create Vercel Account**
   - Go to [vercel.com](https://vercel.com)
   - Sign up with GitHub

3. **Deploy Frontend**
   - Click "Add New" → "Project"
   - Import your GitHub repo
   - Configure:
     - **Framework Preset**: Vite
     - **Root Directory**: `frontend`
     - **Build Command**: `npm run build`
     - **Output Directory**: `dist`
   - Click "Deploy"

4. **Get Frontend URL**
   - Vercel will give you a URL like `https://xiangqi-xxx.vercel.app`
   - Share this with your friends! 🎉

### Step 3: Test Deployment

1. Visit your Vercel URL
2. Try creating a new game
3. Make some moves
4. Test AI opponent
5. Share link with friends!

---

## 🐛 Troubleshooting

### Backend Issues

**Problem**: Backend won't start
```bash
# Solution: Check Python version (need 3.11+)
python --version

# Reinstall dependencies
pip install -r backend/requirements.txt --force-reinstall
```

**Problem**: CORS errors
- Make sure backend `main.py` has `allow_origins=["*"]` in CORS middleware

### Frontend Issues

**Problem**: Frontend can't connect to backend
- Check `frontend/src/api.js` has correct backend URL
- Make sure backend is running first

**Problem**: npm install fails
```bash
# Solution: Clear cache and retry
npm cache clean --force
npm install
```

### Deployment Issues

**Problem**: Render backend crashes
- Check Render logs for errors
- Make sure `requirements.txt` is in root or backend folder
- Verify start command is correct

**Problem**: Vercel build fails
- Make sure Root Directory is set to `frontend`
- Check that `package.json` is in frontend folder

---

## 📝 Alternative Deployment Options

### Railway (Alternative to Render)
1. Go to [railway.app](https://railway.app)
2. Create new project from GitHub
3. Add environment variables if needed
4. Deploy!

### Netlify (Alternative to Vercel)
1. Go to [netlify.com](https://netlify.com)
2. Drag and drop `frontend` folder
3. Done!

---

## 🎯 Production Tips

1. **Add .env file** for API URL instead of hardcoding
2. **Add error handling** for network failures
3. **Add loading states** for better UX
4. **Monitor backend** with Render's built-in monitoring
5. **Use custom domain** (optional, costs money)

---

## 📞 Need Help?

If you encounter issues:
1. Check browser console for errors (F12)
2. Check backend logs on Render
3. Verify both services are running
4. Make sure CORS is configured correctly

Enjoy your game! 🎮象棋
