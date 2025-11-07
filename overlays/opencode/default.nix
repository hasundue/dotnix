# Overlay to patch OpenCode kanagawa theme for transparent backgrounds
# This overlay applies transparency patches to the OpenCode package from nixpkgs

final: prev: {
  opencode = prev.opencode.overrideAttrs (old: {
    postPatch = ''
      echo "Patching kanagawa theme for transparent backgrounds..."
      ${final.jq}/bin/jq '
        .defs.none = "#00000000" |
        .theme.background.dark = "none" |
        .theme.background.light = "none"
      ' packages/opencode/src/cli/cmd/tui/context/theme/kanagawa.json \
        > kanagawa-temp.json
      mv kanagawa-temp.json packages/opencode/src/cli/cmd/tui/context/theme/kanagawa.json

      echo "Patching dialog backdrop to be fully transparent..."
      sed -i 's/backgroundColor={RGBA\.fromInts(0, 0, 0, 150)}/backgroundColor={RGBA.fromInts(0, 0, 0, 0)}/g' \
        packages/opencode/src/cli/cmd/tui/ui/dialog.tsx

      echo "Patching dialog box background to use darker color..."
      sed -i 's/backgroundColor={theme\.backgroundPanel}/backgroundColor={RGBA.fromInts(22, 22, 29, 255)}/g' \
        packages/opencode/src/cli/cmd/tui/ui/dialog.tsx

      echo "Fixing selected text color in dialog-select..."
      sed -i 's/fg={props\.active ? theme\.background/fg={props.active ? theme.backgroundPanel/g' \
        packages/opencode/src/cli/cmd/tui/ui/dialog-select.tsx

      echo "Fixing selected text color in autocomplete..."
      sed -i 's/index() === store\.selected ? theme\.background/index() === store.selected ? theme.backgroundPanel/g' \
        packages/opencode/src/cli/cmd/tui/component/prompt/autocomplete.tsx
    '';
  });
}
