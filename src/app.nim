import prologue

proc hello*(ctx: Context) {.async.} =
  resp "<h1>Hello, App Runner!</h1>"

proc health*(ctx: Context) {.async} =
  # TODO: Can we omit the body alltogether?
  resp "", Http204

let settings = newSettings(debug = false)
var app = newApp(settings = settings)

app.get("/", hello)
app.get("/health", health)
app.run()

