# 🪐 Orbit - a Gemini app framework for Elixir

[![Module Version](https://img.shields.io/hexpm/v/orbit.svg)](https://hex.pm/packages/orbit)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/orbit/)

A simple framework for a simple protocol.

Orbit is a framework for building [Gemini](https://geminiprotocol.net/) applications, known as "capsules".

This framework focuses primarily on the Gemini protocol itself, intent on getting a request into your application,
handling it, and sending a Gemtext response.

It doesn't make any assumptions about your business logic, backing database, migrations, or anything like that.
If you need a database, you can add it manually.

## Concepts

Orbit borrows a lot of ideas from Plug and Phoenix.

- `Orbit.Endpoint` - the TLS server that accepts incoming requests (`Phoenix.Endpoint` + `cowboy`)
- `Orbit.Request` - encapsulates the request-response lifecyle (`Plug.Conn`)
- `Orbit.Pipe` - the behaviour for request middleware (`Plug`)
- `Orbit.Router` - defines pipelines and routes (`Phoenix.Router`)
- `Orbit.Controller` - processes requests (`Phoenix.Controller`)
- `Orbit.Gemtext` - renders Gemtext templates (`Phoenix.Component`)

Some additional niceties:

- `Orbit.Static` - serves up files from `priv/statc` (`Plug.Static`)
- `Orbit.Status` - a canonical list of all status codes
- `Orbit.ClientCertificate` - extracts client certificates from the request

## Installation

Orbit can be added to a new or existing application, including a Phoenix one.

See the [quickstart](https://hexdocs.pm/orbit/Orbit.html#module-quickstart) guide for installation instructions.
