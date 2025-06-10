#!/bin/bash

# Brickhouse Brands - Development Startup Script

echo "🚀 Starting Brickhouse Brands Development Environment"
echo "=================================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command_exists node; then
    echo "❌ Node.js is not installed. Please run './setup-env.sh' first."
    exit 1
fi

if ! command_exists python3; then
    echo "❌ Python 3 is not installed. Please run './setup-env.sh' first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Function to copy centralized env file to subdirectories
copy_env_to_subdir() {
    local subdir=$1
    if [ -f ".env" ] && [ -d "$subdir" ]; then
        echo "📋 Syncing .env to ${subdir}/"
        cp .env "${subdir}/.env"
    fi
}

# Sync centralized environment file to all components
echo ""
echo "📄 Syncing centralized environment configuration..."

if [ ! -f ".env" ]; then
    if [ -f "env.example" ]; then
        echo "⚠️  No .env file found at project root. Creating from env.example..."
        cp env.example .env
        echo "📝 Please edit .env with your actual configuration values before continuing"
    else
        echo "❌ No .env or env.example file found at project root"
        echo "💡 Please create a .env file with your configuration or run './setup-env.sh' first"
        exit 1
    fi
else
    echo "✅ Centralized .env file found"
fi

# Copy to all subdirectories
copy_env_to_subdir "backend"
copy_env_to_subdir "database" 
copy_env_to_subdir "frontend"

echo "✅ Environment files synchronized"

# Check if environments are set up
if [ ! -d "backend/venv" ] || [ ! -d "frontend/node_modules" ]; then
    echo "⚠️  Environment not fully set up. Running setup script..."
    ./setup-env.sh
    if [ $? -ne 0 ]; then
        echo "❌ Environment setup failed. Please check the errors above."
        exit 1
    fi
fi

# Start backend in background
echo ""
echo "🐍 Starting FastAPI Backend..."
cd backend

echo "🔧 Activating virtual environment..."
source venv/bin/activate

echo "🌐 Starting FastAPI server on http://localhost:8000"
python startup.py &
BACKEND_PID=$!

cd ..

# Start frontend
echo ""
echo "⚛️  Starting React Frontend..."
cd frontend

echo "🌐 Starting React development server on http://localhost:5173"
npm run dev &
FRONTEND_PID=$!

cd ..

# Wait and show status
sleep 3
echo ""
echo "🎉 Development environment started successfully!"
echo "=================================================="
echo "📱 Frontend: http://localhost:5173"
echo "🔧 Backend API: http://localhost:8000"
echo "📖 API Docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop all services"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    echo "✅ Services stopped"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

# Wait for processes
wait 