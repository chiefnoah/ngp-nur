{ symlinkJoin, chicago95 }:

symlinkJoin {
  name = "chicago95-theme-${chicago95.version}";
  paths = [ chicago95 ];
  meta = chicago95.meta // {
    description = "Chicago95 retro desktop theme packaged for NGP systems";
  };
}
