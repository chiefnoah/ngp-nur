{ dnscontrol }:

dnscontrol.overrideAttrs (previousAttrs: {
  postPatch = (previousAttrs.postPatch or "") + ''
    substituteInPlace providers/porkbun/porkbunProvider.go \
      --replace-fail \
        'err = rc.SetTarget(c[2])' \
        'err = rc.SetTarget(strings.TrimSuffix(c[2], ".") + ".")'
  '';
})
