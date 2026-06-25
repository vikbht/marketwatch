import SwiftUI
import WebKit



struct FinvizMapView: NSViewRepresentable {
    let urlString: String = "https://finviz.com/map?t=sec&preset_order=true"
    
    func makeNSView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        

        
        // Custom CSS stylesheet injected directly to keep only the treemap canvas and its internal toolbars
        let css = """
        table.header, table.navbar, .footer, div[data-fv-notice], 
        #js-elite-features-root, #notifications-container, 
        #notifications-react-root, #dialogs-react-root, #dialog-portal-root,
        iframe, div[id^="IC_D_"], div[id^="banner_"], div[id^="microbar_"] {
            display: none !important;
        }
        body, html {
            background-color: #101114 !important;
            margin: 0 !important;
            padding: 0 !important;
            overflow: hidden !important;
            width: 100% !important;
            height: 100% !important;
        }
        .content.map {
            padding: 0 !important;
            margin: 0 !important;
            width: 100% !important;
            height: 100% !important;
        }
        .fv-container {
            max-width: 100% !important;
            padding: 0 !important;
            margin: 0 !important;
            width: 100% !important;
            height: 100% !important;
        }
        #root {
            --root-min-height: 0px !important;
            width: 100% !important;
            height: 100% !important;
            min-height: 100% !important;
        }
        #body {
            height: calc(100% - 46px) !important;
            min-height: 0 !important;
        }
        #canvas-wrapper {
            height: 100% !important;
            min-height: 0 !important;
        }
        """
        
        // CSS Injections applied on document start (prevents flashing) and document end (final styling check)
        let docStartJs = """
        var style = document.createElement('style');
        style.innerHTML = `\(css)`;
        document.head.appendChild(style);
        """
        
        let docEndJs = """
        var style = document.createElement('style');
        style.innerHTML = `\(css)`;
        document.head.appendChild(style);
        document.documentElement.classList.add('dark');
        // Enforce pixel height boundaries continuously to override React layout calculation
        var runLayoutFix = function() {
            try {
                var bodyEl = document.getElementById('body');
                var canvasWrapper = document.getElementById('canvas-wrapper');
                var targetHeight = (window.innerHeight - 46) + 'px';
                
                var changed = false;
                if (bodyEl && bodyEl.style.height !== targetHeight) {
                    bodyEl.style.setProperty('height', targetHeight, 'important');
                    bodyEl.style.setProperty('min-height', '0px', 'important');
                    changed = true;
                }
                if (canvasWrapper && canvasWrapper.style.height !== '100%') {
                    canvasWrapper.style.setProperty('height', '100%', 'important');
                    canvasWrapper.style.setProperty('min-height', '0px', 'important');
                    changed = true;
                }
                
                if (changed) {
                    window.dispatchEvent(new Event('resize'));
                }
            } catch(err) {
                // Silent catch
            }
        };
        setInterval(runLayoutFix, 250);
        setTimeout(runLayoutFix, 1000);
        setTimeout(runLayoutFix, 3000);
        setTimeout(runLayoutFix, 5000);
        

        """
        
        let startScript = WKUserScript(source: docStartJs, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        let endScript = WKUserScript(source: docEndJs, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        config.userContentController.addUserScript(startScript)
        config.userContentController.addUserScript(endScript)
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground") // Transparent canvas
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Static component updates handled via WebKit internally
    }
}
