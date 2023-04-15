import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Hooks.DynamicLog (xmobar)
import XMonad.Hooks.ManageDocks

main = xmonad =<< xmobar (docks def
  { terminal          = "alacritty"
  , modMask           = mod4Mask
  , focusFollowsMouse = False
  } `additionalKeysP`
  [ ("<XF86AudioMute>", spawn "pactl set-sink-mute 0 toggle")
  , ("<XF86AudioLowerVolume>", spawn "pactl set-sink-volume 0 -5%")
  , ("<XF86AudioRaiseVolume>", spawn "pactl set-sink-volume 0 +5%")
  , ("<XF86AudioMicMute>", spawn "pactl set-source-mute 1 toggle")
  , ("<XF86MonBrightnessDown>", spawn "brightnessctl s 5%-")
  , ("<XF86MonBrightnessUp>", spawn "brightnessctl s +5%")
  ])
