# 🪐 Orbit - a Gemini app framework for Elixir

[![Module Version](https://img.shields.io/hexpm/v/orbit.svg)](https://hex.pm/packages/orbit)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/orbit/)

A simple framework for a simple protocol.

**🚧 🚧 🚧 Alpha software - under active delopment 🚧 🚧 🚧**

Orbit borrows a lot of ideas from Plug and Phoenix.

- `Orbit.Capsule` - the TLS server that accepts incoming requests (like `Phoenix.Endpoint` + `cowboy`)
- `Orbit.Request` - encapsulates the request-response lifecyle (like `Plug.Conn`)
- `Orbit.Pipe` - the behaviour for request middleware (like `Plug`)
- `Orbit.Router` - defines pipelines and routes
- `Orbit.Controller` - processes requests
- `Orbit.Gemtext` - renders Gemtext templates

- Some additional niceties:

  - `Orbit.Static` - serves up files from `priv/statc`
  - `Orbit.Status` - applies status codes to `Orbit.Request`

## There's still a lot TODO!

See the [GitHub project](https://github.com/users/schrockwell/projects/1/views/1) for the latest progress.

## Installation

Orbit can be added to any existing application, including a Phoenix one.

See the [Quick Start](https://hexdocs.pm/orbit/Orbit.html#module-quick-start) guide for installation instructions.
