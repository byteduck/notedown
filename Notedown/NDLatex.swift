//
//  NDLatex.swift
//  Notedown
//
//  Created by Aaron on 5/4/23.
//

import MathJaxSwift
import WebKit

class NDLatexRenderingContext: NSObject, WKNavigationDelegate {
    let latex: String
    let webView = WKWebView()
    
    /// For some reason, unless we wrap the SVG in an <img>, the rendering is blurry. Why? Who knows!
    private var svg = ""
    private var svgDataUrl: String {
        "data:image/svg+xml;charset=utf-8;base64,\(svg.toBase64())"
    }
    private var htmlString: String {
        """
        <html>
            <head>
                <meta name="viewport" content="width=device-width">
                <style>
                    body, html {
                        padding: 0;
                        margin: 0;
                    }
        
                    #latex {
                        padding: 5px;
                        margin: 0;
                    }
                </style>
            </head>
            <body>
                <img id="latex" src="\(svgDataUrl)" />
            </body>
        </html>
        """
    }
    
    private let onReady: (NSImage) -> Void
    
    // Maintain a strong reference to ourself to stay allocated until we're done
    private var selfRef: NDLatexRenderingContext?
    
    init(latex: String, onReady: @escaping (NSImage) -> Void) {
        self.latex = latex
        self.onReady = onReady
        super.init()
        
        guard
            let mathJax = try? MathJax(),
            let svg = try? mathJax.tex2svg(latex)
        else {
            return
        }
        self.svg = svg
        webView.navigationDelegate = self
        webView.loadHTMLString(htmlString, baseURL: nil)
        self.selfRef = self
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.selfRef = nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            Task {
                guard let width = try? await webView.evaluateJavaScript("document.getElementById('latex').clientWidth") as? Int,
                      let height = try? await webView.evaluateJavaScript("document.getElementById('latex').clientHeight") as? Int
                else {
                    self.selfRef = nil
                    return
                }
                
                webView.setFrameSize(NSSize(width: width, height: height))
                self.generateWebViewImage()
            }
        }
    }
    
    private func generateWebViewImage() {
        webView.takeSnapshot(with: nil) { image, error in
            if let image = image {
                self.onReady(image)
            }
            self.selfRef = nil
        }
    }
}

func renderLatex(_ latex: String, onReady: @escaping (NSImage) -> Void) {
    _ = NDLatexRenderingContext(latex: latex, onReady: onReady)
}
