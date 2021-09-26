//
//  LoginViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/3/31.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import WebKit
import PromiseKit

class LoginViewController: NSViewController {
    @IBOutlet weak var tryAgainButton: NSButton!
    @IBAction func tryAgain(_ sender: Any) {
        initViews()
    }
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var resultTextField: NSTextField!
    enum Tabs: Int {
        case webView, progress, result
    }
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var viewForWeb: NSView!
    var thirdPartyWebView: WKWebView?
    let loginURL = URL(string: "https://music.163.com/#/login")
    let discoverURL = URL(string: "https://music.163.com/#/discover")
    
    
    @IBAction func Refresh(_ sender: NSButton) {
        initViews()
    }

    private var checkingCookies = false
    private var cookieStoreObserverStarted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        clearCookies()
    }
    
    func initViews() {
        if let isReachable = PlayCore.shared.api.reachabilityManager?.isReachable,
           !isReachable {
            showUnknownError()
        } else {
            startCookieStoreObserver()
            checkingCookies = false
            tryAgainButton.isEnabled = false
            thirdPartyWebView?.isHidden = true
            thirdPartyWebView = nil
            webView.stopLoading()
            webView.load(URLRequest(url: URL(string:"about:blank")!))
            
            selectTab(.progress)
            loadWebView()
        }
    }
    
    func loadWebView() {

        webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1 Safari/605.1.15"
        let request = URLRequest(url: loginURL!)
        webView.load(request)
    }
    
    func clearCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    
    func selectTab(_ tab: Tabs) {
        if tab == .progress {
            progressIndicator.startAnimation(nil)
        } else {
            progressIndicator.stopAnimation(nil)
        }
        
        tabView.selectTabViewItem(at: tab.rawValue)
    }
    
    func showUnknownError() {
        selectTab(.result)
        resultTextField.stringValue = "未知错误."
        tryAgainButton.isEnabled = true
    }
    
    func evaluateLoginJS() -> Promise<()> {
        let script = """
// top bar
document.getElementsByClassName("g-topbar")[0].style.display='none';
document.getElementsByClassName("g-btmbar")[0].style.display='none';

// button controller
document.getElementById('g_iframe').contentDocument.getElementsByClassName("g-ft")[0].style.display='none';

// top bar ackground
document.getElementById('g_iframe').contentDocument.getElementsByClassName('m-top')[0].style.display='none';
document.getElementById('g_iframe').contentDocument.getElementsByClassName('m-subnav')[0].style.display='none';
"""
        return evaluateJavaScript(script).map { _ in }
    }
    
    func evaluateJavaScript(_ script: String) -> Promise<Any?> {
        Promise { resolver in
            webView.evaluateJavaScript(script) { re, error in
                if let e = error {
                    resolver.reject(e)
                }
                resolver.fulfill(re)
            }
        }
    }
    
    func syncCookies() -> Promise<()> {
        Promise { resolver in
            WKWebsiteDataStore.default().httpCookieStore.getAllCookies {
                $0.forEach {
                    HTTPCookieStorage.shared.setCookie($0)
                }
                resolver.fulfill_()
            }
        }
    }
    
    func startCookieStoreObserver(_ start: Bool = true) {
        let httpCookieStore = WKWebsiteDataStore.default().httpCookieStore
        if start, !cookieStoreObserverStarted {
            httpCookieStore.add(self)
        } else if !start, cookieStoreObserverStarted {
            httpCookieStore.remove(self)
        }
        
    }
    
    deinit {
        startCookieStoreObserver(false)
    }
}


extension LoginViewController: WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        guard let url = webView.url,
              let urlC = URLComponents(string: url.absoluteString),
              urlC.host == "music.163.com"
              else {
            return
        }
        
        switch urlC.fragment {
        case "/login":
            evaluateLoginJS().done {
                self.selectTab(.webView)
            }.catch {
                Log.error("\($0)")
            }
        default:
            break
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard webView.url == loginURL else {
            Log.info("createWebView from unknown webview.")
            return nil
        }
        
        Log.info("")
        
        thirdPartyWebView = WKWebView(frame: NSZeroRect, configuration: configuration)
        guard let tWebView = thirdPartyWebView else { return nil }
        tWebView.navigationDelegate = self
        viewForWeb.subviews.removeAll()
        viewForWeb.addSubview(tWebView)
        
        // webview layout
        tWebView.translatesAutoresizingMaskIntoConstraints = false
        let attributes: [NSLayoutConstraint.Attribute] = [.top, .bottom, .right, .left]
        NSLayoutConstraint.activate(attributes.map {
            NSLayoutConstraint(item: tWebView, attribute: $0, relatedBy: .equal, toItem: viewForWeb, attribute: $0, multiplier: 1, constant: 0)
        })
        
        return thirdPartyWebView
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard webView == thirdPartyWebView, webView.url?.host == "music.163.com" else { return }
        
        webView.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nserr = error as NSError
        if nserr.code == -1022 {
            Log.error("NSURLErrorAppTransportSecurityRequiresSecureConnection")
        } else if let err = error as? URLError {
            switch(err.code) {
            case .cancelled:
                break
            case .cannotFindHost, .notConnectedToInternet, .resourceUnavailable, .timedOut:
                Log.error("Can't load web.")
            default:
                Log.error("Error code: " + String(describing: err.code) + "  does not fall under known failures")
            }
        }
        
        showUnknownError()
    }
}

extension LoginViewController: WKHTTPCookieStoreObserver {
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        cookieStore.getAllCookies {
            let names = $0.map {
                $0.name
            }
            
            guard Set(names).intersection(["MUSIC_U", "__csrf"]).count == 2,
                  !self.checkingCookies else {
                return
            }
            
            Log.info("Login Cookies Passed.")
            
            self.checkingCookies = true
            self.selectTab(.progress)
            
            self.webView.stopLoading()
            self.webView.load(URLRequest(url: URL(string:"about:blank")!))
            
            self.syncCookies().then {
                PlayCore.shared.api.nuserAccount()
            }.ensure {
                self.checkingCookies = false
            }.done { _ in
                Log.info("Login Success.")
                NotificationCenter.default.post(name: .updateLoginStatus, object: nil)
                self.startCookieStoreObserver(false)
            }.catch {
                Log.error("\($0)")
                self.showUnknownError()
            }
        }
    }
}
