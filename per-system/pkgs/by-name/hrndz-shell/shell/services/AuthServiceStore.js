// Intentionally not `.pragma library`: QML JavaScript imports get a private
// module instance per importing component. shell.qml's instance retains the
// authentication services; any other component importing this file receives a
// separate empty store rather than a shared path to credential-bearing QML.

var services = ({})

function put(id, service) {
  var key = String(id || "")
  if (!key || !service) return
  if (services[key] && services[key] !== service && typeof services[key].destroy === "function")
    services[key].destroy()
  services[key] = service
}
