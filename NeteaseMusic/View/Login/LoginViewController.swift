//
//  LoginViewController.swift
//  NeteaseMusic
//
//  Created by xjbeta on 2019/3/31.
//  Copyright © 2019 xjbeta. All rights reserved.
//

import Cocoa
import WebKit

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
    let loginUrlStr = URL(string: "https://music.163.com/#/login")
    var shouldTryAgain = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        clearCookies()
        initViews()
    }
    
    func initViews() {
        tryAgainButton.isEnabled = false
        thirdPartyWebView = nil
        thirdPartyWebView?.isHidden = true
        progressIndicator.startAnimation(nil)
        selectTab(.progress)
        loadWebView()
    }
    
    func loadWebView() {
        
        webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1 Safari/605.1.15"
        let request = URLRequest(url: loginUrlStr!)
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
        tabView.selectTabViewItem(at: tab.rawValue)
    }
    
    func showUnknownError() {
        selectTab(.result)
        resultTextField.stringValue = "Unkown error."
        shouldTryAgain = true
        tryAgainButton.isEnabled = true
    }
    
}


extension LoginViewController: WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url == loginUrlStr {
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
            if webView.url == loginUrlStr {
                webView.evaluateJavaScript(script) { (_, err) in
                    print(err ?? "")
                }
            }
            selectTab(.webView)
        }
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard webView.url == loginUrlStr else {
            print("createWebView from unknown webview.")
            return nil
        }
        
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
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let urlStr = navigationAction.request.url?.absoluteString else {
            decisionHandler(.cancel)
            return
        }
        
        if urlStr.starts(with: "https://music.163.com/back") {
            selectTab(.progress)
        } else if urlStr == "https://music.163.com/discover" {
            selectTab(.progress)
            PlayCore.shared.api.isLogin().done(on: .main) {
                if $0 {
                    // Login Success.
                    let vc = self.view.window?.contentViewController as? MainViewController
                    vc?.updateMainTabView(.main)
                } else {
                    self.resultTextField.stringValue = "Login Failed."
                    self.selectTab(.result)
                    self.tryAgainButton.isEnabled = true
                }

                }.catch(on: .main) {
                    print("Check login status error: \($0)")
                    self.showUnknownError()
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nserr = error as NSError
        if nserr.code == -1022 {
            print("NSURLErrorAppTransportSecurityRequiresSecureConnection")
        } else if let err = error as? URLError {
            switch(err.code) {
            case .cancelled:
                break
            case .cannotFindHost, .notConnectedToInternet, .resourceUnavailable, .timedOut:
                print("Can't load web.")
            default:
                print("Error code: " + String(describing: err.code) + "  does not fall under known failures")
            }
        }
    }
}
