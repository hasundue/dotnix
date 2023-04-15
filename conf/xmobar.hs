Config { font = "FiraCode Nerd Font 12"
       , additionalFonts = ["FiraCode Nerd Font italic 12"]
       , borderColor = "black"
       , border = FullB
       , bgColor = "black"
       , fgColor = "whitesmoke"
       , alpha = 128
       , position = Top
       , textOffset = -1
       , iconOffset = -1
       , lowerOnStart = True
       , pickBroadest = False
       , persistent = False
       , hideOnStart = False
       , iconRoot = "."
       , allDesktops = True
       , overrideRedirect = True
       , textOutputFormat = Ansi
       , commands = [ Run Weather "EGPF" ["-t","<station>: <tempC>C",
                                          "-L","18","-H","25",
                                          "--normal","green",
                                          "--high","red",
                                          "--low","lightblue"] 36000
                    , Run Network "eth0" ["-L","0","-H","32",
                                          "--normal","green","--high","red"] 10
                    , Run Network "eth1" ["-L","0","-H","32",
                                          "--normal","green","--high","red"] 10
                    , Run Cpu ["-L","3","-H","50",
                               "--normal","green","--high","red"] 10
                    , Run Memory ["-t","Mem: <usedratio>%"] 10
                    , Run Swap [] 10
                    , Run Com "uname" ["-s","-r"] "" 36000
                    , Run Date "%a %b %_d %Y %H:%M:%S" "date" 10
                    ]
       , sepChar = "%"
       , alignSep = "}{"
       , template = "%cpu% | <box>%memory% * %swap%</box> | %eth0% - %eth1% }\
                    \{ <fc=#ee9a00><fn=1>%date%</fn></fc>| %EGPF% | %uname%"
       }
