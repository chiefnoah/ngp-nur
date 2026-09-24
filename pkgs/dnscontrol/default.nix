{ dnscontrol, lib }:

dnscontrol.overrideAttrs (previousAttrs: {
  postPatch =
    (previousAttrs.postPatch or "")
    + (
      if lib.versionOlder dnscontrol.version "5.0" then
        ''
          # Older DNSControl uses SetTarget for Porkbun SRV records.
          substituteInPlace providers/porkbun/porkbunProvider.go \
            --replace-fail \
              'err = rc.SetTarget(c[2])' \
              'err = rc.SetTarget(strings.TrimSuffix(c[2], ".") + ".")'
        ''
      else
        ''
          # Porkbun returns absolute SRV targets without a trailing dot.
          substituteInPlace providers/porkbun/porkbunProvider.go \
            --replace-fail \
              'rc, err = dc.NewRecordConfig(label, ttl, dnsv2.TypeSRV, priority, c[0], c[1], c[2])' \
              'rc, err = dc.NewRecordConfig(label, ttl, dnsv2.TypeSRV, priority, c[0], c[1], strings.TrimSuffix(c[2], ".") + ".")'
        ''
    );
})
