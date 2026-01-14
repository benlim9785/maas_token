#!/bin/bash
# Setup script for ModelArk Token Processing Cronjob

# Check for --no-run parameter
NO_RUN=false
if [[ "$1" == "--no-run" ]]; then
    NO_RUN=true
    echo "Setting up daily cronjob for ModelArk token processing (no immediate run)..."
else
    echo "Setting up daily cronjob for ModelArk token processing..."
fi

# Navigate to the project directory (parent of scripts)
PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$PROJECT_DIR"

USERNAME=$(whoami)

# Create logs directory if it doesn't exist
mkdir -p logs

# Create the cron job entry for 9 AM daily
CRON_ENTRY="0 9 * * * cd $PROJECT_DIR && source venv/bin/activate && python3 task.py"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "python3 task.py"; then
    echo "❌ Cronjob already exists!"
    echo "Current cronjobs:"
    crontab -l | grep "python3 task.py"
    echo ""
    echo "To remove existing cronjob, run: crontab -e"
    exit 1
fi

# Add the cron job to crontab
echo "Adding cronjob to crontab..."
(crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -

echo "✅ Cronjob successfully added!"
echo ""
echo "📋 Details:"
echo "  Schedule: Daily at 9:00 AM"
echo "  Command: $CRON_ENTRY"
echo "  Log files: $PROJECT_DIR/logs/task_YYYYMMDD_HHMMSS.log"
echo ""

# Run immediately for today (if not disabled)
if [ "$NO_RUN" = false ]; then
    echo "🚀 Running task immediately for today..."
    echo "This will process tokens with today's randomized target..."
    echo ""

    # Check if virtual environment exists
    if [ ! -d "venv" ]; then
        echo "❌ Virtual environment not found! Please create venv first."
        exit 1
    fi

    # Run the task in background and show progress
    echo "Starting task.py in background..."
    source venv/bin/activate && python3 task.py &
    TASK_PID=$!

    echo "✅ Task started with PID: $TASK_PID"
    echo ""
    echo "📊 Monitor progress:"
    echo "  ls -la $PROJECT_DIR/logs/  # Find the latest log file"
    echo "  tail -f $PROJECT_DIR/logs/task_*.log  # Watch the latest log"
    echo ""
    echo "🔍 Check if running:"
    echo "  ps aux | grep $TASK_PID"
    echo ""
    echo "⏹️  To stop if needed:"
    echo "  kill $TASK_PID"
    echo ""
else
    echo "⏭️  Skipping immediate run (use without --no-run to run immediately)"
    echo ""
fi

echo "📅 Next scheduled run: Tomorrow at 9:00 AM"
echo ""
echo "🔍 To verify cronjob installation:"
echo "  crontab -l"
echo ""
echo "🗑️  To remove cronjob:"
echo "  sh remove_cronjob.sh  # then delete the line"