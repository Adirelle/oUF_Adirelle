#!/usr/bin/env bash
set -eux

update() {
    local TARGET="$1"

    if ! grep -q -e '--<GLOBALS' "$TARGET"; then
        echo "No GLOBALS comments in $TARGET, skipped" >&2
        return 0
    fi

    echo "Processing $TARGET" >&2

    cp "$TARGET" "$TARGET.__bak"
    trap "mv $TARGET.__bak $TARGET" ERR
    trap "rm -f $TARGET.__*" EXIT

    sed -e '0,/--<GLOBALS/p' -e 'd' "$TARGET" >"$TARGET.__before"
    sed  -e '/--GLOBALS>/,$p' -e 'd' "$TARGET" >"$TARGET.__after"

    cat "$TARGET.__before" "$TARGET.__after" \
        | luac -l -p -  \
        | awk '$3=="GETGLOBAL"&&$7!="_G"{print"local "$7" = assert(_G."$7", \"_G."$7" is undefined\")"}' \
        | sort -u \
        > "$TARGET.__globals"

    cat "$TARGET.__before" "$TARGET.__globals" "$TARGET.__after" \
        | stylua - \
        > "$TARGET"

    return 0
}

for FILE in "$@"; do
    (
        update "$FILE"
    )
done
