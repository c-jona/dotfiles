{ ... }:
final: prev:
{
  xorg = prev.xorg // {
    xinit = prev.xorg.xinit.overrideAttrs (
      prevAttrs:
        {
          postFixup = prevAttrs.postFixup + ''
            sed -i 's/^    xserverauthfile="\$HOME\/\.serverauth\.\$\$"$/    xserverauthfile="$HOME\/.Xauthority"/' $out/bin/startx
          '';
        }
    );
  };
}
