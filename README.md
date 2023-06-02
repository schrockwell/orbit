# 🪐 Orbit - a Gemini app framework for Elixir

[![Module Version](https://img.shields.io/hexpm/v/orbit.svg)](https://hex.pm/packages/orbit)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/orbit/)

A simple framework for a simple protocol.

**🚧 🚧 🚧 Alpha software - under active delopment 🚧 🚧 🚧**

Orbit borrows a lot of ideas from Plug and Phoenix.

- The foundation consists of:

  - `Orbit.Capsule` - TLS endpoint that accepts incoming connections (like `Phoenix.Endpoint` and `cowboy` combined)
  - `Orbit.Request` - encapsulates the request-response lifecyle (like `Plug.Conn`)

- Your application implements:

  - `Orbit.Pipe` - the behaviour for request middleware (like `Plug`)
  - `Orbit.Router` - defines pipelines and routes
  - `Orbit.Controller` - processes requests and render views
  - `Orbit.View` - renders Gemtext content

- Some additional niceties:

  - `Orbit.Static` - serves up static content
  - `Orbit.Status` - applies response status codes

## There's still a lot TODO!

See the [GitHub project](https://github.com/users/schrockwell/projects/1/views/1) for the latest progress.

## Installation

Orbit can be added to any existing application, including a Phoenix one.

See the [Quick Start](https://hexdocs.pm/orbit/Orbit.html#module-quick-start) guide for installation instructions.
