import prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, AWS App Runner!</h1>"

proc health*(ctx: Context) {.async} =
  resp "OK", Http200

let settings = newSettings(debug = false)
var app = newApp(settings = settings)

app.get("/", hello)
app.get("/health", health)
app.run()
