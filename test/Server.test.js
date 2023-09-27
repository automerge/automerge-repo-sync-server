// @ts-check

import assert from "assert"
import { before, after } from "mocha"
import { WebSocket } from "ws"

import { BrowserWebSocketClientAdapter } from "@automerge/automerge-repo-network-websocket"
import { Repo } from "@automerge/automerge-repo"
import { Server } from "../src/server.js"

describe("Sync Server Tests", () => {
  let server

  const PORT =
    process.env.PORT !== undefined ? parseInt(process.env.PORT) : 3030
  before(async () => {
    server = new Server()

    await server.ready()
  })

  after(() => {
    server.close()
  })

  it("runs the server correctly", (done) => {
    const ws = new WebSocket(`ws://localhost:${PORT}`)

    ws.on("open", () => {
      done()
    })
  })

  it("can sync a document with the server and get back the same document", (done) => {
    const repo = new Repo({
      network: [new BrowserWebSocketClientAdapter(`ws://localhost:${PORT}`)],
    })

    const repo2 = new Repo({
      network: [new BrowserWebSocketClientAdapter(`ws://localhost:${PORT}`)],
    })

    const handle = repo.create()

    handle.change((doc) => {
      doc.test = "hello world"
    })

    const handle2 = repo2.find(handle.url)

    handle2.doc().then((doc) => {
      assert.equal(doc.test, "hello world")
      done()
    })
  })

  it("withholds existing documents from new peers until they request them", async () => {
    const repo = new Repo({
      network: [new BrowserWebSocketClientAdapter(`ws://localhost:${PORT}`)],
    })

    const handle = repo.create()

    handle.change((doc) => {
      doc.test = "hello world"
    })

    // wait to give the server time to sync the document
    await new Promise((resolve) => setTimeout(resolve, 100))

    const repo2 = new Repo({
      network: [new BrowserWebSocketClientAdapter(`ws://localhost:${PORT}`)],
    })

    assert.equal(Object.keys(repo2.handles).length, 0)

    const handle2 = repo2.find(handle.url)

    assert.equal(Object.keys(repo2.handles).length, 1)

    const doc = await handle2.doc()

    assert.equal(doc.test, "hello world")
  })
})
