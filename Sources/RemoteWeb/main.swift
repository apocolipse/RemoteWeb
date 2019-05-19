import Foundation
import Swifter
import Dispatch
import LIRC

let server = HttpServer()
var cachedRemotes: String = ""
let commandQueue = DispatchQueue.global(qos: .background)

let lirc = LIRC(socketPath: RemoteConfig.socketPath)

server.GET["/remotes.json"] = LoggingRequestHandler { request in
  if cachedRemotes != "" && cachedRemotes != "{}" {
    return .ok(.text(cachedRemotes))
  }
  var json: [String: [String]] = [:]
  if lirc.allRemotes.count == 0 {
    do {
      try lirc.refreshRemotes()
    } catch let error {
      print("Error fetching remotes \(error)")
    }
  }
  lirc.allRemotes.forEach { remote in
    json[remote.name] = remote.commands.map { $0.name }
  }
  cachedRemotes = json.json
  return .ok(.text(json.json))
}

server.GET["/refresh"] = LoggingRequestHandler { request in
  commandQueue.async { try? lirc.refreshRemotes() }
  cachedRemotes = ""
  return .movedPermanently("/")
}

server.GET["/remotes/:remote"] = LoggingRequestHandler(TryingRequestHandler{ request in
  guard let param = request.params[":remote"],
        param.contains(".json"),
        let remote = param.split(separator: ".").first else { return .notFound }
    let r = try lirc.remote(named: String(remote))
  return .ok(.text(r.commands.map({ $0.name }).json))
})



// Handler for handing all command send requests
let SendCommandHandler: (SendType) -> RequestHandler = { sendType in
  return TryingRequestHandler { request in
    guard let remoteParam = request.params[":remote"],
          let commandParam   = request.params[":command"] else { return .notFound }
    var s = sendType
    if case .once = sendType  {
      if let countString = request.queryParams.filter({$0.0 == "count" }).first?.0,
        let count = Int(countString) {
        s = .count(count)
      }
    }
    try lirc.remote(named: remoteParam).command(String(commandParam)).send(s)
    return .ok(.text("OK"))
  }
}

server.POST["/remotes/:remote/:command"]            = LoggingRequestHandler(SendCommandHandler(.once))
server.POST["/remotes/:remote/:command/send_start"] = LoggingRequestHandler(SendCommandHandler(.start))
server.POST["/remotes/:remote/:command/send_start"] = LoggingRequestHandler(SendCommandHandler(.stop))

server.GET["/macros.json"]    = LoggingRequestHandler({ _ in .ok(.text(RemoteConfig.macros.json)) })

// TODO:  Support more complex macro's, i.e. count
server.POST["/macros/:macro"] = LoggingRequestHandler(TryingRequestHandler { request in
  guard let macroParam = request.params[":macro"],
        let macro = RemoteConfig.macros[macroParam] else { return .notFound }
  for step in macro {
    if step[0] == "delay" {
      usleep((UInt32(step[1]) ?? 1) * 1000)
    } else {
      try lirc.remote(named: step[0]).command(step[1]).send()
    }
  }
  
  return .ok(.text("OK"))
})

server.GET["/"]               = LoggingRequestHandler(RemoteTemplates.index(with: lirc.allRemotes))
server["js/compiled/:path"]   = LoggingRequestHandler(shareFilesFromDirectory("/var/lib/lirc_web/compiled")) // TODO: FIXME)
server["css/compiled/:path"]  = LoggingRequestHandler(shareFilesFromDirectory("/var/lib/lirc_web/compiled")) // TODO: FIXME

let semaphore = DispatchSemaphore(value: 0)
do {
  try server.start(RemoteConfig.ServerConfig.port, forceIPv4: RemoteConfig.ServerConfig.forceIPv4, priority: .userInitiated)
  print("Swift RemoteWeb Open Source Univeral Remote UI + API has started on \(RemoteConfig.ServerConfig.port) (http).")
  semaphore.wait()
} catch let error{
  print("Server error: \(error)")
  semaphore.signal()
}

