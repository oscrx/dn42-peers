# dn42-peers

The BGP peers of AS4242423818 (oscrx) in [DN42](https://dn42.dev): one
`DN42Peer` per file in `peers/`, named `<asn>-<name>.yaml`. ArgoCD syncs this
repo into the `dn42-router` namespace, and
[dn42-operator](https://github.com/oscrx/dn42-operator) turns each file into
a WireGuard tunnel and a BIRD session.

ArgoCD is public (read-only, no login needed): see the sync state of this
repo in the
[`dn42-peers` app](https://argocd.lab.oscarr.nl/applications/argocd/dn42-peers),
and the rest of the router in
[`dn42-router`](https://argocd.lab.oscarr.nl/applications/argocd/dn42-router). The rest of the
cluster's config is in
[bierteam/uber-kubernetes](https://github.com/bierteam/uber-kubernetes).

```yaml
apiVersion: dn42.oscarr.nl/v1alpha1
kind: DN42Peer
metadata:
  name: iedon            # wg-iedon; 1-12 of [a-z0-9], starting with a letter
spec:
  asn: 4242422189
  listenPort: 22189      # our port; always set explicitly here
  endpoint: "[2001:bc8:1640:5bdb:dc00:ff:fe60:c2e3]:60887"   # optional
  publicKey: 08dzv758I5APqJizgw/W6O+FceyHSCbx/L/GZ3TL5TQ=
  localLinkLocal: fe80::3818   # optional, default fe80::3818
  neighbor: fe80::2189:177
  link: {latency: 2, bandwidth: 24, crypto: 34}   # optional; else latency is measured
  keyRef: iedon          # hand-managed peers only: our private key for this tunnel
```

## Requesting a peering

Use the autopeer page (log in with a DN42 identity provider). It opens a PR
here with your file, and the PR is merged automatically once the check
passes. Autopeers use our shared key, so their files have no `keyRef`. You
can also open a PR by hand; those are reviewed by a human.

All data here is public: no private keys, only references (`keyRef`) to keys
stored elsewhere.

## The check

`.github/workflows/check.yaml` runs `peercheck` from dn42-operator, pinned to a
release, on every PR and every push to `main`.

- **Every file**: exactly one YAML document, a strict schema (unknown fields,
  `status`, labels and annotations are rejected), `kind: DN42Peer`, a
  namespace of `dn42` or none, and a file name that matches the name and ASN.
  The spec gets the operator's own validation: ASN ranges, port range,
  link-local addresses, key format and link values.
- **Registry**: the ASN must have an aut-num object in the DN42 registry.
- **Across files**: no duplicate name, listen port, or ASN + neighbor.
- **PR shape**:
  - A PR from the autopeer App may only touch `peers/`, may not set
    `keyRef`, and may not change or delete a hand-managed peer (one with
    `keyRef`). Breaking any of these fails the check.
  - Human PRs may touch anything. They are marked not auto-mergeable and
    wait for review.
- **Auto-merge**: only for a PR from the App that changes exactly one peer
  file, with everything green.

Run it locally against a dn42-operator checkout next to this one:

```
REGISTRY=~/src/dn42-registry hack/check.sh              # tree check
REGISTRY=~/src/dn42-registry hack/check.sh --base main  # PR check of HEAD
```

Repository settings that must be set by hand are in
[docs/repository-settings.md](docs/repository-settings.md).

## License

MIT, see [LICENSE](LICENSE).
