#!/bin/bash

# Token Processing Status Checker
# Quick script to check the status of your daily token processing

SCRIPT_DIR="/Users/bytedance/Desktop/maas_token"
LOG_DIR="$SCRIPT_DIR/logs"

echo "=========================================="
echo "Token Processing Status Check"
echo "=========================================="

# Check if cron job exists
echo "1. Cron Job Status:"
CRON_ENTRY=$(crontab -l 2>/dev/null | grep -E "(run_daily_task\.sh|run_with_catchup\.sh)")
if [ -n "$CRON_ENTRY" ]; then
    echo "   ✅ Cron job is configured:"
    echo "$CRON_ENTRY" | sed 's/^/   /'

    # Check if using catch-up version
    if echo "$CRON_ENTRY" | grep -q "run_with_catchup.sh"; then
        echo "   🚀 Using smart catch-up version"
    else
        echo "   ⚠️  Using basic version (consider upgrading to run_with_catchup.sh)"
    fi
else
    echo "   ❌ No cron job found"
fi

echo ""

# Check if task is currently running
echo "2. Current Task Status:"
RUNNING_TASK=$(pgrep -f "python.*task.py")
if [ -n "$RUNNING_TASK" ]; then
    echo "   🔄 Task is currently running (PID: $RUNNING_TASK)"
else
    echo "   ⏸️  No task currently running"
fi

echo ""

# Check latest log
echo "3. Latest Execution:"
if [ -f "$LOG_DIR/latest.log" ]; then
    echo "   📝 Latest log file: $(readlink "$LOG_DIR/latest.log")"
    echo "   📅 Last modified: $(stat -f "%Sm" "$LOG_DIR/latest.log")"
    echo ""
    echo "   Last 5 lines:"
    tail -5 "$LOG_DIR/latest.log" | sed 's/^/     /'
else
    echo "   ❌ No logs found"
fi

echo ""

# Check cached response file
echo "4. Cache Status:"
if [ -f "$SCRIPT_DIR/cached_response.json" ]; then
    echo "   ✅ Cached response file exists"
    echo "   📅 Last modified: $(stat -f "%Sm" "$SCRIPT_DIR/cached_response.json")"
else
    echo "   ❌ No cached response file"
fi

echo ""

# Check last successful run (for catch-up mechanism)
echo "5. Last Successful Run:"
if [ -f "$SCRIPT_DIR/.last_successful_run" ]; then
    LAST_RUN=$(cat "$SCRIPT_DIR/.last_successful_run")
    TODAY=$(date '+%Y-%m-%d')
    echo "   📅 Last successful run: $LAST_RUN"

    if [ "$LAST_RUN" = "$TODAY" ]; then
        echo "   ✅ Task completed today"
    else
        # Calculate days since last run
        LAST_TIMESTAMP=$(date -j -f "%Y-%m-%d" "$LAST_RUN" "+%s" 2>/dev/null)
        TODAY_TIMESTAMP=$(date -j -f "%Y-%m-%d" "$TODAY" "+%s")

        if [ -n "$LAST_TIMESTAMP" ] && [ -n "$TODAY_TIMESTAMP" ]; then
            DAYS_SINCE=$(( (TODAY_TIMESTAMP - LAST_TIMESTAMP) / 86400 ))
            if [ $DAYS_SINCE -eq 1 ]; then
                echo "   ⚠️  Last run was yesterday - may need catch-up"
            elif [ $DAYS_SINCE -gt 1 ]; then
                echo "   🚨 Last run was $DAYS_SINCE days ago - catch-up needed"
            fi
        fi
    fi
else
    echo "   ❓ No run history found (first time setup?)"
fi

echo ""

# Show recent executions
echo "6. Recent Executions (last 7 days):"
if [ -d "$LOG_DIR" ]; then
    find "$LOG_DIR" -name "task_*.log" -mtime -7 -exec basename {} \; | sort | sed 's/^/   📊 /'

    if [ $(find "$LOG_DIR" -name "task_*.log" -mtime -7 | wc -l) -eq 0 ]; then
        echo "   📭 No executions in the last 7 days"
    fi
else
    echo "   ❌ Logs directory not found"
fi

echo ""

# Configuration check
echo "7. Configuration:"
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "   ✅ .env file exists"
    TARGET=$(grep "TARGET_TOKEN_MILLION" "$SCRIPT_DIR/.env" | cut -d'=' -f2)
    echo "   🎯 Target: $TARGET million tokens"
else
    echo "   ❌ .env file not found"
fi

echo ""
echo "=========================================="
echo "Status check completed"
echo "=========================================="