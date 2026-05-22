// Kanagawa Wave Color Palette
// https://github.com/rebelot/kanagawa.nvim

import QtQuick

QtObject {
    id: colors

    // ── Background layers ────────────────────────────────────────────
    property color bg:           "#1F1F28"   // dragonBlack0
    property color bgAlt:        "#252535"   // dragonBlack3
    property color bgHighlight:  "#2D2E30"   // sumiInk3
    property color border:       "#3B3C3F"   // sumiInk4
    property color surface:      "#16161D"   // sumiInk0 (deepest)

    // ── Foreground ───────────────────────────────────────────────────
    property color fg:           "#DCD7BA"   // fujiWhite (primary text)
    property color fgDim:        "#C8C093"   // oldWhite (subtext)
    property color fgMuted:      "#727169"   // sumiInk3 grey (muted)

    // ── Accents ──────────────────────────────────────────────────────
    property color red:          "#E46876"   // waveRed
    property color green:        "#98BB6C"   // springGreen
    property color blue:         "#7E9CD8"   // crystalBlue
    property color cyan:         "#7AA89F"   // waveAqua1
    property color yellow:       "#FF9E3B"   // autumnYellow / roninYellow
    property color magenta:      "#D27E99"   // sakanaPink
    property color teal:         "#7FB4CA"   // waveBlue
    property color orange:       "#FFA066"   // surimiOrange

    // ── Semantic Aliases ─────────────────────────────────────────────
    property color wsActive:     blue        // Active workspace indicator
    property color wsOccupied:   cyan        // Workspace has windows
    property color wsEmpty:      bgHighlight // Unused workspace
    property color wsUrgent:     red         // Urgent workspace

    // Qt falls back to the default font automatically if this family is missing
    property string fontFamily:  "JetBrains Mono Nerd Font"
}
