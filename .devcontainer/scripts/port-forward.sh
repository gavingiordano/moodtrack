#!/usr/bin/env bash
# port-forward.sh - Manage port forwarding using socat
# Usage:
#   port-forward.sh start <port1> [port2] [port3] ...
#   port-forward.sh stop [port1] [port2] ...  (if no ports specified, stops all)
#   port-forward.sh status
#   port-forward.sh restart <port1> [port2] ...

set -euo pipefail

SCRIPT_NAME=$(basename "$0")
PID_DIR="/tmp/port-forward-pids"
LOG_DIR="/tmp/port-forward-logs"

# Ensure directories exist
mkdir -p "$PID_DIR" "$LOG_DIR"

# Get target container IP from compose service
get_target_ip() {
    local port=$1
    local container_ip=""
    
    # Try to find which container is using this port
    local container_name
    container_name=$(docker ps --format '{{.Names}}\t{{.Ports}}' 2>/dev/null | grep -E "0\.0\.0\.0:${port}->" | awk '{print $1}' | head -1)
    
    if [ -n "$container_name" ]; then
        # Get the container's IP address on its network
        container_ip=$(docker inspect "$container_name" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
        if [ -n "$container_ip" ]; then
            echo "$container_ip"
            return 0
        fi
    fi
    
    # Fallback: can't determine specific container, return empty
    echo ""
    return 1
}

# Check if socat is available
check_socat() {
    if ! command -v socat >/dev/null 2>&1; then
        echo "Error: socat is not installed" >&2
        echo "Install it with: apt-get update && apt-get install -y socat" >&2
        exit 1
    fi
}

# Start forwarding a single port
start_port() {
    local port=$1
    local pid_file="$PID_DIR/$port.pid"
    local log_file="$LOG_DIR/$port.log"

    # Check if already running
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Port $port is already being forwarded (PID: $pid)"
            return 0
        else
            # Stale PID file, remove it
            rm -f "$pid_file"
        fi
    fi

    # Check if port is already in use
    if netstat -tln 2>/dev/null | grep -q ":$port " || ss -tln 2>/dev/null | grep -q ":$port "; then
        echo "Error: Port $port is already in use locally" >&2
        return 1
    fi

    # Try to find the target container and its internal port
    local container_name mapped_port target_ip internal_port
    container_name=$(docker ps --format '{{.Names}}\t{{.Ports}}' 2>/dev/null | grep -E "0\.0\.0\.0:${port}->" | awk '{print $1}' | head -1)
    
    if [ -z "$container_name" ]; then
        echo "Error: No container found with port mapping 0.0.0.0:$port" >&2
        echo "Available port mappings:" >&2
        docker ps --format '{{.Names}}\t{{.Ports}}' | grep "0.0.0.0" >&2
        return 1
    fi
    
    # Extract the internal port from the mapping (e.g., 0.0.0.0:8001->8000/tcp gives us 8000)
    mapped_port=$(docker ps --format '{{.Ports}}' --filter "name=$container_name" 2>/dev/null | grep -oE "${port}->([0-9]+)" | cut -d'>' -f2)
    
    if [ -z "$mapped_port" ]; then
        echo "Error: Could not determine internal port for container $container_name" >&2
        return 1
    fi
    
    # Get container's IP address
    target_ip=$(docker inspect "$container_name" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
    
    if [ -z "$target_ip" ]; then
        echo "Error: Could not determine IP for container $container_name" >&2
        return 1
    fi
    
    internal_port=$mapped_port
    
    echo "Forwarding localhost:$port -> $container_name($target_ip:$internal_port)"

    # Start socat in background
    socat TCP-LISTEN:"$port",fork,reuseaddr TCP:"$target_ip":"$internal_port" > "$log_file" 2>&1 &
    local socat_pid=$!
    
    # Save PID
    echo "$socat_pid" > "$pid_file"
    
    # Wait a moment and verify it's still running
    sleep 0.2
    if kill -0 "$socat_pid" 2>/dev/null; then
        echo "✓ Started forwarding port $port (PID: $socat_pid)"
        return 0
    else
        rm -f "$pid_file"
        echo "Error: Failed to start forwarding port $port" >&2
        if [ -s "$log_file" ]; then
            echo "Log output:" >&2
            cat "$log_file" >&2
        fi
        return 1
    fi
}

# Stop forwarding a single port
stop_port() {
    local port=$1
    local pid_file="$PID_DIR/$port.pid"
    
    if [ ! -f "$pid_file" ]; then
        echo "Port $port is not being forwarded"
        return 0
    fi
    
    local pid
    pid=$(cat "$pid_file")
    
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        sleep 0.1
        # Force kill if still running
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
        echo "✓ Stopped forwarding port $port (PID: $pid)"
    else
        echo "Port $port was not running (cleaning up stale PID file)"
    fi
    
    rm -f "$pid_file"
}

# Show status of all forwarded ports
show_status() {
    local any_active=false
    
    echo "Port Forwarding Status"
    echo "======================"
    
    if [ ! -d "$PID_DIR" ] || [ -z "$(ls -A "$PID_DIR" 2>/dev/null)" ]; then
        echo "No ports are being forwarded"
        return 0
    fi
    
    for pid_file in "$PID_DIR"/*.pid; do
        [ -e "$pid_file" ] || continue
        local port
        port=$(basename "$pid_file" .pid)
        local pid
        pid=$(cat "$pid_file")
        
        if kill -0 "$pid" 2>/dev/null; then
            # Try to get target info from docker ps
            local container_name target_ip internal_port
            container_name=$(docker ps --format '{{.Names}}\t{{.Ports}}' 2>/dev/null | grep -E "0\.0\.0\.0:${port}->" | awk '{print $1}' | head -1)
            if [ -n "$container_name" ]; then
                target_ip=$(docker inspect "$container_name" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1)
                internal_port=$(docker ps --format '{{.Ports}}' --filter "name=$container_name" 2>/dev/null | grep -oE "${port}->([0-9]+)" | cut -d'>' -f2)
                echo "✓ Port $port -> $container_name($target_ip:$internal_port) (PID: $pid) [ACTIVE]"
            else
                echo "✓ Port $port (PID: $pid) [ACTIVE]"
            fi
            any_active=true
        else
            echo "✗ Port $port (PID: $pid) [DEAD - stale PID file]"
            rm -f "$pid_file"
        fi
    done
    
    if [ "$any_active" = false ]; then
        echo "No active port forwards"
    fi
}

# Stop all forwarded ports
stop_all() {
    local any_stopped=false
    
    if [ ! -d "$PID_DIR" ] || [ -z "$(ls -A "$PID_DIR" 2>/dev/null)" ]; then
        echo "No ports are being forwarded"
        return 0
    fi
    
    for pid_file in "$PID_DIR"/*.pid; do
        [ -e "$pid_file" ] || continue
        local port
        port=$(basename "$pid_file" .pid)
        stop_port "$port"
        any_stopped=true
    done
    
    if [ "$any_stopped" = false ]; then
        echo "No ports were being forwarded"
    fi
}

# Main command dispatcher
main() {
    local command=${1:-}
    
    if [ -z "$command" ]; then
        echo "Usage: $SCRIPT_NAME {start|stop|status|restart} [ports...]"
        echo ""
        echo "Commands:"
        echo "  start <port> [port2] ...   Start forwarding specified port(s)"
        echo "  stop [port] [port2] ...    Stop forwarding specified port(s) (or all if none specified)"
        echo "  status                     Show status of all forwarded ports"
        echo "  restart <port> [port2] ... Restart forwarding specified port(s)"
        echo ""
        echo "Examples:"
        echo "  $SCRIPT_NAME start 8001 8002 6379"
        echo "  $SCRIPT_NAME stop 8001"
        echo "  $SCRIPT_NAME stop              # stops all"
        echo "  $SCRIPT_NAME status"
        echo "  $SCRIPT_NAME restart 8001"
        exit 1
    fi
    
    shift
    
    case "$command" in
        start)
            if [ $# -eq 0 ]; then
                echo "Error: No ports specified" >&2
                exit 1
            fi
            check_socat
            for port in "$@"; do
                if ! [[ "$port" =~ ^[0-9]+$ ]]; then
                    echo "Error: Invalid port number: $port" >&2
                    continue
                fi
                start_port "$port" || true
            done
            ;;
        stop)
            if [ $# -eq 0 ]; then
                stop_all
            else
                for port in "$@"; do
                    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
                        echo "Error: Invalid port number: $port" >&2
                        continue
                    fi
                    stop_port "$port"
                done
            fi
            ;;
        status)
            show_status
            ;;
        restart)
            if [ $# -eq 0 ]; then
                echo "Error: No ports specified" >&2
                exit 1
            fi
            check_socat
            for port in "$@"; do
                if ! [[ "$port" =~ ^[0-9]+$ ]]; then
                    echo "Error: Invalid port number: $port" >&2
                    continue
                fi
                echo "Restarting port $port..."
                stop_port "$port"
                start_port "$port" || true
            done
            ;;
        *)
            echo "Error: Unknown command: $command" >&2
            echo "Use '$SCRIPT_NAME' without arguments to see usage" >&2
            exit 1
            ;;
    esac
}

main "$@"
