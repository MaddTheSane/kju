if [ $# -eq 0 ]; then
    echo "Usage: killall9 NAME"
    exit
fi

PIDSTT=$(eval "ps x | grep $1 | awk '{print \$1}'")
for PID in $PIDSTT;
do
    if (ps -p $PID | grep $PID) &>/dev/null; then
        if kill -9 $PID; then
            echo "Killed $PID"
        else
            echo "could not kill $PID"
        fi
    fi
done
