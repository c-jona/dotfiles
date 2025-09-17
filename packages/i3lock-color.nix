{
  i3lock-color,
  makeWrapper,
  symlinkJoin
}: symlinkJoin {
  name = "i3lock-color-wrapped";
  paths = [ i3lock-color ];
  buildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/i3lock-color --add-flags '--screen=0 --blur=5 --force-clock --indicator --radius=90 --ring-width=12 --inside-color=#07080ac0 --ring-color=#07080a --insidever-color=#07080ac0 --ringver-color=#a093c7 --insidewrong-color=#07080ac0 --ringwrong-color=#07080a --line-uses-inside --keyhl-color=#b4be82 --bshl-color=#e27878 --separator-color=#00000000 --ind-pos="w/2:h/2 + r + 30" --time-str="%H:%M:%S" --time-color=#c6c8d1 --time-font="monospace:bold" --time-size=120 --time-pos="w/2:h/2 - 120" --timeoutline-color=#07080a --timeoutline-width=1 --date-str="%A, %d %B %Y" --date-color=#c6c8d1 --date-font="monospace:bold" --date-size=30 --date-pos="tx:ty + 60" --dateoutline-color=#07080a --dateoutline-width=0.5 --greeter-text="󰌾" --greeter-color=#c6c8d1 --greeter-font="monospace:bold" --greeter-size=60 --greeter-pos="ix:iy + 20" --greeteroutline-color=#07080a --greeteroutline-width=1 --verif-text="" --wrong-text="" --noinput-text="" --lock-text="" --lockfailed-text="" --no-modkey-text'
  '';
}
