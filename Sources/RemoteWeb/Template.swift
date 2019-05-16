import Swifter
import LIRC

struct RemoteTemplates {
  static func index(with remotes: [Remote]) -> ((HttpRequest) -> HttpResponse) {
    return scopes {
      html {
        head {
          meta { name = "mobile-web-app-capable";                 content = "yes"   }
          meta { name = "apple-mobile-web-app-capable";           content = "yes"   }
          meta { name = "apple-mobile-web-app-status-bar-style";  content = "black" }
          meta { charset = "UTF-8" }
          meta { httpEquiv = "content-type";                      content = "text/html; charset=utf-8" }
          meta { name = "viewport";                               content = "width=device-width" }
          meta { name = "viewport";                               content = "initial-scale = 1.0,maximum-scale = 1.0" }
          title { inner = "Universal Remote" }
          link { rel="stylesheet";  href = "css/compiled/compiled.css" }
        }
        body { ontouchstart = ""
          div { idd = "container"
            h1 { idd = "titlebar"
              a { classs = "back hidden"; div { classs = "left-arrow" }}
              span { idd = "title"; dataText = "Universal Remote"; inner = "Universal Remote" }
            }
            p { classs="offline-message";
              inner = "You are currently offline. "
              a { idd = "offline-retry"; href = "/"; inner = "Retry?"}
            }
            ul { classs = "remotes-nav"
              for remote in remotes {
                li{ a { classs = "btn btn-wide btn-large btn-info"; href = "#\(remote.name)"; inner = remote.label } }
              }
            }
            
            hr {}
            
            ul { classs = "macros-nav"
              for macro in RemoteConfig.macros.keys {
                li { button { classs = "btn btn-wide btn-large btn-warning macro-link"; href = "/macros/\(macro.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "ERROR")"; inner = macro; }}
              }
            }
            
            div { classs = "prev" }
            
            ul { classs = "remotes"
              for remote in remotes {
                li { classs = "remote"; idd = remote.name
                  ul { classs = "commands"
                    for command in remote.commands {
                      li { classs = "command"
                        button { classs = "command-link \(command.repeats ? "command-repeater" : "command-once") btn btn-wide btn-large btn-primary"; href = "/remotes/\(remote.name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "ERROR")/\(command.name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "ERROR")"; inner = command.label }
                      }
                    }
                  }
                }
              }
            } // /ul
            
          } // /div
          
          div { classs = "next" }
          
          footer {
            p { a { href = "/refresh"; inner = "Refresh" }}
            p { a { href = "http://opensourceuniversalremote.com/"; inner = "Powered by Open Source Universal Remote" }}
            p { a { href = "http://github.com/apocolipse/RemoteWeb"; inner = "Swift version Remote Web by Apocolipse"}}
          }
          script { src = "js/compiled/app.js"; type="text/javascript"; charset="utf-8"}
          
        } // /body
      } // /html
    } // scopes
  } // index
}
