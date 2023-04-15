import XMonad
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Hooks.DynamicLog (xmobar)
import XMonad.Hooks.ManageDocks

main = xmonad =<< xmobar (docks def
  { terminal          = "alacritty"
  , modMask           = mod4Mask
  , focusFollowsMouse = False
  } `additionalKeysP`
  [ ("<XF86MonBrightnessDown>", spawn "brightnessctl s 10%-")
  , ("<XF86MonBrightnessUp>", spawn "brightnessctl s +10%")
  ])
