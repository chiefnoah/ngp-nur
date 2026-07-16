{
  cacert,
  curl,
  fetchFromGitHub,
  jq,
  lib,
  stdenvNoCC,
  unzip,
}:

let
  fetchOpenDesktopFile =
    {
      name,
      contentId,
      link,
      hash,
    }:
    stdenvNoCC.mkDerivation {
      inherit name;
      nativeBuildInputs = [
        curl
        jq
      ];
      SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
      outputHash = hash;
      outputHashMode = "flat";
      buildCommand = ''
        url="$(curl --fail --location --silent \
          "https://api.opendesktop.org/ocs/v1/content/data/${toString contentId}?format=json" \
          | jq --raw-output '.data[0].downloadlink${toString link}')"
        curl --fail --location --output "$out" "$url"
      '';
    };

  gtkTheme = fetchOpenDesktopFile {
    name = "Mac-OS-9-Platinum-Default.zip";
    contentId = 1749681;
    link = 2;
    hash = "sha256-nMfqlMmI08DFX0k/E7qcRPaQkUqnxlzNjcUtXlXYwZ0=";
  };
  panelAssets = fetchOpenDesktopFile {
    name = "PanelAssets.zip";
    contentId = 1749681;
    link = 6;
    hash = "sha256-X3QkFzigWOKZ5gtOE1Ror5BevzpVfiGgsnQ/piX8Ryk=";
  };
  iconTheme = fetchOpenDesktopFile {
    name = "NineIcons48x.tar.gz";
    contentId = 1749686;
    link = 1;
    hash = "sha256-/0BWDMktYz0lukv4JNoO0iYbH2wAvjv48n5jyz+UGJc=";
  };
  platinum9 = fetchFromGitHub {
    owner = "timnetworks";
    repo = "Platinum9";
    rev = "f0b7214e00a72ca8c0b71a949f1268db90dc216a";
    hash = "sha256-esbrewfzFLedRBhJrUKPvUnsn6sKSJjWMzxeUYHs8jo=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "macos9-platinum-theme";
  version = "1.5";

  src = platinum9;
  nativeBuildInputs = [ unzip ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p \
      "$out/share/backgrounds/macos9-platinum" \
      "$out/share/fonts/truetype" \
      "$out/share/icons" \
      "$out/share/lxqt/themes/macos9-platinum" \
      "$out/share/macos9-platinum/panel" \
      "$out/share/themes"

    unzip -q ${gtkTheme} -d "$out/share/themes"
    tar -xzf ${iconTheme} -C "$out/share/icons"
    unzip -q ${panelAssets} -d "$out/share/macos9-platinum"

    # gtk-update-icon-cache rejects whitespace in icon filenames.
    mv "$out/share/icons/NineIcons48x/apps/16/Internet Explorer_2_16x16x8.png" \
      "$out/share/icons/NineIcons48x/apps/16/internet-explorer-2.png"

    cp -r OS9-wallpaper/. "$out/share/backgrounds/macos9-platinum"
    cp Charcoal.ttf MONACO.TTF "$out/share/fonts/truetype"
    cp -r PlatiPlus PlatiPlus26 "$out/share/themes"
    cp ${./lxqt-config.qss} "$out/share/lxqt/themes/macos9-platinum/lxqt-config.qss"
    cp ${./lxqt-panel.qss} "$out/share/lxqt/themes/macos9-platinum/lxqt-panel.qss"
    cp ${./lxqt-config.qss} "$out/share/lxqt/themes/macos9-platinum/lxqt-notificationd.qss"
    cp ${./lxqt-config.qss} "$out/share/lxqt/themes/macos9-platinum/lxqt-runner.qss"
    cp "$out/share/icons/NineIcons48x/menu/apple.png" \
      "$out/share/lxqt/themes/macos9-platinum/apple.png"
    cp "$out/share/macos9-platinum/PanelAssets/middle.png" \
      "$out/share/lxqt/themes/macos9-platinum/panel-bottom.png"
    cp ${./panel-top.svg} "$out/share/lxqt/themes/macos9-platinum/panel-top.svg"

    runHook postInstall
  '';

  meta = {
    description = "Mac OS 9 Platinum GTK, XFWM, icon, font, panel, and wallpaper themes";
    homepage = "https://www.xfce-look.org/p/1749681";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
