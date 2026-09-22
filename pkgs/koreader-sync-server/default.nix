{
  fetchFromGitHub,
  gnused,
  lib,
  openresty,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "koreader-sync-server";
  version = "0-unstable-2026-09-22";

  src = fetchFromGitHub {
    owner = "koreader";
    repo = "koreader-sync-server";
    rev = "d941a63acd6e9a2d13b3e6bbc2fe40ee7c39e149";
    hash = "sha256-d8yBOIV7zuES30lLugSa0bde38DeFZFoShhJaJXhf0g=";
  };

  ginSrc = fetchFromGitHub {
    owner = "ostinelli";
    repo = "gin";
    rev = "cb35e87fa0671fcf25e5bce5cb9487dee8b497e2";
    hash = "sha256-HUtqs1nx659eSpBupTGVyoe/BW5HmhJTaoIKLjIzidM=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/koreader-sync-server
    cp -r app config db $out/share/koreader-sync-server
    mkdir -p $out/share/koreader-sync-server/lib/gin
    cp -r $ginSrc/gin/* $out/share/koreader-sync-server/lib/gin
    chmod -R u+w $out/share/koreader-sync-server

    cat > $out/share/koreader-sync-server/lib/gin/helpers/common.lua <<'EOF'
    local CommonHelpers = {}

    function CommonHelpers.try_require(module_name, default)
      local ok, result = pcall(require, module_name)
      if ok then return result end
      if string.match(result, "'" .. module_name .. "' not found") then return default end
      error(result)
    end

    return CommonHelpers
    EOF

    substituteInPlace $out/share/koreader-sync-server/db/redis.lua \
      --replace-fail 'port = 6379' 'port = tonumber(os.getenv("KOSYNC_REDIS_PORT"))'
    substituteInPlace $out/share/koreader-sync-server/lib/gin/core/router.lua \
      --replace-fail "package.path = './app/controllers/?.lua;' .. package.path" \
        "package.path = '$out/share/koreader-sync-server/app/controllers/?.lua;' .. package.path"

    mkdir -p $out/bin
    cat > $out/bin/koreader-sync-server <<EOF
    #!${stdenvNoCC.shell}
    set -eu

    runtime_dir=/run/koreader-sync-server
    ${gnused}/bin/sed "s/@KOSYNC_PORT@/\$KOSYNC_PORT/" \
      $out/share/koreader-sync-server/nginx.conf > "\$runtime_dir/nginx.conf"

    exec ${openresty}/bin/openresty -g 'daemon off;' -p "\$runtime_dir" -c "\$runtime_dir/nginx.conf"
    EOF
    chmod +x $out/bin/koreader-sync-server

    cat > $out/share/koreader-sync-server/nginx.conf <<EOF
    worker_processes auto;
    pid /run/koreader-sync-server/nginx.pid;
    error_log stderr notice;

    events { worker_connections 1024; }

    http {
      access_log /dev/stdout;
      lua_code_cache on;
      lua_package_path "$out/share/koreader-sync-server/?.lua;$out/share/koreader-sync-server/lib/?.lua;;";

      server {
        listen 127.0.0.1:@KOSYNC_PORT@;

        location / {
          content_by_lua 'require("gin.core.router").handler(ngx)';
        }
      }
    }
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Synchronization server for KOReader";
    homepage = "https://github.com/koreader/koreader-sync-server";
    license = lib.licenses.agpl3Only;
    mainProgram = "koreader-sync-server";
  };
})
