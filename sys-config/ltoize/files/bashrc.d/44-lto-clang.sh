LTO_CLANG_FULL() {
    if [[ ${LTO_FULL} -eq 1 ]]; then
        export CFLAGS="${CFLAGS//=thin}"
        export CXXFLAGS="${CXXFLAGS//=thin}"
        export LDFLAGS="${LDFLAGS//=thin}"
    fi
}

# Applications that depend on dev-qt programs SIGABRT at runtime with LTO
LTO_CLANG_QT() {
    if [[ ${RDEPEND} =~ dev-qt || ${DEPEND} =~ dev-qt ]]; then
        export CFLAGS="${CFLAGS//=thin}"
        export CFLAGS="${CFLAGS//-flto}"
        export CXXFLAGS="${CXXFLAGS//=thin}"
        export CXXFLAGS="${CXXFLAGS//-flto}"
        export LDFLAGS="${LDFLAGS//=thin}"
        export LDFLAGS="${LDFLAGS//-flto}"
    fi
}

BashrcdPhase configure LTO_CLANG_FULL
BashrcdPhase configure LTO_CLANG_QT
