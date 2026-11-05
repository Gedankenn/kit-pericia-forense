# VHS tape — demo GIF do kit pericia forense v1.4.8
# Replay do transcript real (EQ99 / PeritoTeste) na VM de teste.
# Deps: vhs (charmbracelet) + ttyd + ffmpeg + Chrome.
#
# Gerar:
#   vhs docs/img/coleta_demo.tape
#   # se o GIF sair > ~2 MB, comprimir mantendo ~15-20s:
#   ffmpeg -y -i docs/img/coleta_demo.gif \
#     -vf "fps=10,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=36:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" \
#     -loop 0 /tmp/coleta_ok.gif && mv /tmp/coleta_ok.gif docs/img/coleta_demo.gif

Output docs/img/coleta_demo.gif

Set Shell bash
Set FontSize 14
Set FontFamily "DejaVu Sans Mono"
Set Width 900
Set Height 500
Set Padding 14
Set Margin 20
Set MarginFill "#0b0904"
Set BorderRadius 10
Set WindowBar Colorful
Set WindowBarSize 32
Set Theme {"name":"KitAmber","black":"#1a1200","red":"#ff5a45","green":"#7CFF9E","yellow":"#FFB000","blue":"#4FC3F7","magenta":"#E040FB","cyan":"#67E8F9","white":"#FFE7A8","brightBlack":"#6B5420","brightRed":"#FF8A7A","brightGreen":"#B0FFC8","brightYellow":"#FFD56A","brightBlue":"#81D4FA","brightMagenta":"#F48FB1","brightCyan":"#A5F3FC","brightWhite":"#FFF6DE","background":"#120e04","foreground":"#FFB000","selection":"#3a2a00","cursor":"#FFB000"}
Set CursorBlink false
Set TypingSpeed 40ms
Set Framerate 12
Set PlaybackSpeed 1.1

Hide
Type@0ms "cd /workspace/kit-pericia-forense && clear"
Enter
Show

Sleep 300ms
Type "./docs/img/coleta_demo_replay.sh"
Enter
Sleep 450ms

Type "EQ99"
Enter
Sleep 220ms
Type "PeritoTeste"
Enter

Sleep 15s
