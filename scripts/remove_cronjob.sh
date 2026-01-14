#!/bin/bash
# Remove ModelArk Token Processing Cronjob and Kill Running Processes

echo "Removing ModelArk token processing cronjob and stopping running processes..."

# Check if cron job exists
if ! crontab -l 2>/dev/null | grep -q "python3 task.py"; then
    echo "❌ No cronjob found for task.py"
    exit 1
fi

echo "Found existing cronjob:"
crontab -l | grep "python3 task.py"
echo ""

# Check for running task.py processes
RUNNING_PIDS=$(ps aux | grep "python.*task.py" | grep -v grep | awk '{print $2}')

if [ -n "$RUNNING_PIDS" ]; then
    echo "🔍 Found running task.py processes:"
    ps aux | grep "python.*task.py" | grep -v grep
    echo ""

    echo "🛑 Killing running task.py processes..."
    for PID in $RUNNING_PIDS; do
        echo "  Killing PID: $PID"
        kill $PID 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "  ✅ Process $PID stopped successfully"
        else
            echo "  ⚠️  Failed to stop process $PID (may have already ended)"
        fi
    done
    echo ""

    # Wait a moment and verify processes are stopped
    sleep 2
    STILL_RUNNING=$(ps aux | grep "python.*task.py" | grep -v grep | awk '{print $2}')
    if [ -n "$STILL_RUNNING" ]; then
        echo "⚠️  Some processes are still running, forcing termination..."
        for PID in $STILL_RUNNING; do
            echo "  Force killing PID: $PID"
            kill -9 $PID 2>/dev/null
        done
    else
        echo "✅ All task.py processes stopped successfully"
    fi
    echo ""
else
    echo "ℹ️  No running task.py processes found"
    echo ""
fi

# Remove the cron job
echo "📅 Removing cronjob from crontab..."
crontab -l 2>/dev/null | grep -v "python3 task.py" | crontab -

echo "✅ Cronjob successfully removed!"
echo ""
echo "🧹 Cleanup complete:"
echo "  • Cronjob removed from crontab"
echo "  • All running task.py processes stopped"
echo ""
echo "🔍 Verify removal:"
echo "  crontab -l"
echo "  ps aux | grep task.py"