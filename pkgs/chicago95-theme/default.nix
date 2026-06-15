{ symlinkJoin, chicago95, lib }:

symlinkJoin {
  name = "chicago95-theme-${chicago95.version}";
  paths = [ chicago95 ];

  meta = {
    description = "Chicago95 retro desktop theme packaged for NGP systems";
    homepage = "https://github.com/grassmunk/Chicago95";
    license = with lib.licenses; [
      gpl3Plus
      mit
    ];
    maintainers = [
      {
        email = "noah@packetlost.dev";
        github = "chiefnoah";
        githubId = 3588683;
        name = "Noah Pederson";
      }
    ];
    platforms = lib.platforms.linux;
  };
}
