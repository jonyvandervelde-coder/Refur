import WebKit

/// Serves the bundled Refur web app (Resources/www) over a fixed custom
/// scheme ("app://refur/...") instead of a file:// URL.
///
/// This matters for one reason: WKWebView's localStorage behavior for
/// file:// origins has historically been inconsistent across iOS versions
/// (the "origin" for a local file load isn't always treated as stable
/// between launches). Streaks, feathers, and shields all live in
/// localStorage, so losing them on an iOS update would be a real problem.
/// A custom scheme with a fixed host gives the web view the same stable
/// origin ("app://refur") every single launch, so localStorage persists
/// exactly the way it does on a real website.
final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {

    static let scheme = "app"
    static let host = "refur"

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              let wwwDir = Bundle.main.url(forResource: "www", withExtension: nil) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        var relativePath = url.path
        if relativePath.isEmpty || relativePath == "/" {
            relativePath = "/index.html"
        }

        let fileURL = wwwDir.appendingPathComponent(relativePath)

        guard let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let response = URLResponse(
            url: url,
            mimeType: Self.mimeType(for: fileURL.pathExtension),
            expectedContentLength: data.count,
            textEncodingName: "utf-8"
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // No cancellable work in flight -- reads are synchronous above.
    }

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html": return "text/html"
        case "js":   return "application/javascript"
        case "json": return "application/json"
        case "css":  return "text/css"
        case "png":  return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "svg":  return "image/svg+xml"
        default:     return "application/octet-stream"
        }
    }
}
