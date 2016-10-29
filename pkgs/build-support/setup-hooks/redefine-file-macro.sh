postFixupHooks+=(_redefineFileMacro _addSetupHook)

_redefineFileMacro() {
    echo "replacing __FILE__ with __NIX_FILE__"

    cd "$dev"
    find include \( -name '*.hpp' -or -name '*.h' -or -name '*.ipp' \) \
        -exec sed\
            -e '1i#pragma push_macro("__NIX_FILE__")' \
            -e '1i#define __NIX_FILE__ "{}"' \
            -e '$a#pragma pop_macro("__NIX_FILE__")' \
            -e 's/__FILE__/__NIX_FILE__/' \
            -i '{}' \;
}

_addSetupHook() {
    echo "add -D __NIX_FILE__=__FILE__ to a setup hook"

    mkdir -p "$dev/nix-support"
    echo 'export NIX_CFLAGS_COMPILE+=" -D__NIX_FILE__=__FILE__"' >> "$dev/nix-support/setup-hook"
}
