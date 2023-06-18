# Orbit Changelog

## v0.2.1

- Add `X509` dependency and new `Orbit.ClientCertificate` struct
- Improve `OrbitTest` for client certificates, etc.
- Improve `Orbit.Static` to serve up `index.gmi` files when they exist
- Drop generated status functions from `Orbit.Status`
- Add `mix orbit.server` (MVP, still needs some work)
- Change path of self-signed cert in `mix orbit.gen.cert`
- Add `embed_templates/1` to formatter export
