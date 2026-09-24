{ dnscontrol }:

dnscontrol.overrideAttrs (previousAttrs: {
  postPatch = (previousAttrs.postPatch or "") + ''
    # Porkbun returns absolute SRV targets without a trailing dot.
    substituteInPlace providers/porkbun/porkbunProvider.go \
      --replace-fail \
        'rc, err = dc.NewRecordConfig(label, ttl, dnsv2.TypeSRV, priority, c[0], c[1], c[2])' \
        'rc, err = dc.NewRecordConfig(label, ttl, dnsv2.TypeSRV, priority, c[0], c[1], strings.TrimSuffix(c[2], ".") + ".")'
  '';
})
