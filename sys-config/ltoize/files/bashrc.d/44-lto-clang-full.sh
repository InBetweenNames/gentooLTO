LTO_CLANG_FULL() {
    if [[ ${LTO_FULL} -eq 1 ]]; then
        export CFLAGS="${CFLAGS//=thin}"
        export CXXFLAGS="${CXXFLAGS//=thin}"
        export LDFLAGS="${LDFLAGS//=thin}"
    fi
}

BashrcdPhase configure LTO_CLANG_FULL
