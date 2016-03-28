//
//  AppDelegate.swift
//  StreamcloudGrabber
//
//  Created by Tom Albrecht on 28.03.16.
//  Copyright © 2016 Tom Albrecht. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    @IBOutlet weak var textField : NSTextField!
    @IBOutlet weak var label : NSTextField!
    @IBOutlet weak var progressIndicator : NSProgressIndicator!
    
    var conn : NSURLConnection?
    var totalSize : Int64?
    var dlData : NSMutableData?
    
    var step = 0
    var fname : String?
    var id : String?
    var file : String?
    
    var resumedLength : Int = 0
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        label.stringValue = ""
        
        //self.progressIndicator.doubleValue = 50.0
        window.titlebarAppearsTransparent = true
        window.movableByWindowBackground = true
        window.styleMask = window.styleMask
        window.backgroundColor = NSColor.whiteColor()
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
    
    
    
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        // done!!!
        
        if step == 0 {
            let contents = NSString(data:dlData!, encoding:NSUTF8StringEncoding)
            dlData = nil
            dlData = NSMutableData()
            step = 1
            
            // dumb code for testing
            file = contents!.componentsSeparatedByString("file: \"")[1].componentsSeparatedByString("\",")[0]
            
            self.label.stringValue = ("Downloading Video, Please wait...")
            
            let r = NSURLRequest(URL: NSURL(string: file!)!)
            
            
            conn = nil
            conn = NSURLConnection(request: r, delegate: self)
            conn?.start();
            
        } else if step == 1 {
            
            
            self.label.stringValue = ("Saving Video to Desktop...")
            do {
                try dlData!.writeToFile(NSHomeDirectory()+"/Desktop/"+fname!+".mp4", options:NSDataWritingOptions.AtomicWrite)
                self.label.stringValue = ("Done, saved video to Desktop!")
                
            } catch _ {
                self.label.stringValue = ("Error writing to file. Nothing to do here")
            }
            
            
            dlData = nil
            dlData = NSMutableData()
            
        }
        
        
        
    }
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        // failed
        label.stringValue = "Something failed in step " + String(step+1) + "."
    }
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        // go for it
        totalSize = response.expectedContentLength
    }
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        // data one by one
        dlData!.appendData(data)
        self.progressIndicator.doubleValue = Double(dlData!.length) / Double(totalSize! + resumedLength) * 100.0;
    }
    
    
    
    
    @IBAction func stopDL(sender: NSButton) {
        conn?.cancel();
        label.stringValue = "Stopped download manually. Click the resume button to continue downloading."
    }
    
    @IBAction func resumeDL(sender: NSButton) {
        step = 1
        
        label.stringValue = "Resuming download! Please wait..."
        
        resumedLength = dlData!.length
        
        let r = NSMutableURLRequest(URL: NSURL(string: file!)!)
        r.setValue("bytes="+String(dlData!.length)+"-", forHTTPHeaderField: "Range")
        
        conn = nil
        conn = NSURLConnection(request: r, delegate: self)
        conn?.start();
    }
    
    @IBAction func funkyStuff(sender : NSButton) {
        textField.resignFirstResponder()
        
        resumedLength = 0
        
        step = 0
        dlData = nil
        dlData = NSMutableData()
        
        
        let urlString = textField.stringValue;
        let ar = urlString.componentsSeparatedByString("/")
        id = ar[3]
        fname = ar.last!.componentsSeparatedByString(".html")[0];
        
        var postData = "op=download1&"
        postData += "id="+id!+"&"
        postData += "referer=&hash=&"
        postData += "imhuman=Weiter+zum+Video&"
        postData += "fname="+fname!+"&"
        
        
        let url = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: url!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
        request.HTTPMethod = "POST"
        request.setValue("streamcloud.eu", forHTTPHeaderField: "Host")
        request.setValue(urlString, forHTTPHeaderField: "Referer")
        request.HTTPBody = postData.dataUsingEncoding(NSUTF8StringEncoding)
        
        
        if (conn) != nil {
            conn?.cancel()
            conn = nil
        }
        
        label.stringValue = ("Getting Video URL...")
        
        conn = NSURLConnection(request: request, delegate: self)
        conn?.start();
    }
}

