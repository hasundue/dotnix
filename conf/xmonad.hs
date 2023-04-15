import XMonad
import XMonad.Hooks.DynamicLog

main = xmonad =<< xmobar def
	{ terminal	= "alacritty"
	}
