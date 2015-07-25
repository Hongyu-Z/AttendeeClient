//
//  ViewController.swift
//  SwiftAttendees
//
//  Created by Zhu, Hongyu on 7/23/15.
//  Copyright (c) 2015 Zhu, Hongyu. All rights reserved.
//

import UIKit
import AFNetworking
import IOSLinkedInAPI

let LINKEDIN_CLIENT_ID: String = "75qpogf438frch"
let LINKEDIN_CLIENT_SECRET: String = "6G2SveM77DOAiDpJ"


class ViewController: UIViewController {
    
    var client:LIALinkedInHttpClient = {
        var application:LIALinkedInApplication = LIALinkedInApplication.applicationWithRedirectURL("http://www.ancientprogramming.com/", clientId: LINKEDIN_CLIENT_ID, clientSecret: LINKEDIN_CLIENT_SECRET, state: "DCEEFWF45453sdffef424", grantedAccess: ["r_basicprofile"]) as! LIALinkedInApplication
        return LIALinkedInHttpClient(forApplication: application,presentingViewController: nil)
    }()
    var delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapConnectWithLinkedIn(sender: AnyObject) {
        
//        client.getAuthorizationCode(<#success: ((String!) -> Void)!##(String!) -> Void#>, cancel: <#(() -> Void)!##() -> Void#>, failure: <#((NSError!) -> Void)!##(NSError!) -> Void#>)
        
        client.getAuthorizationCode(
            {(authCode:String!)->Void in self.client.getAccessToken(authCode,
                success: { (accessTokenData: [NSObject: AnyObject]!) in
                    var accessToken:String = accessTokenData["access_token"] as! String
//                    NSLog(accessToken)
                    self.requestMeWithToken(accessToken)
                },
                failure: {(error: NSError!)->Void in NSLog("Quering accessToken failed %@", error)})
            },
            cancel: {NSLog("Authorization was cancelled by user")},
            failure: {(error: NSError!)->Void in NSLog("Authorization failed %@", error)})
        
    }
    
    func requestMeWithToken(accessToken: String) {
        let url:String! = "https://api.linkedin.com/v1/people/~?oauth2_access_token=\(accessToken)&format=json"

//        client.GET(<#URLString: String!#>, parameters: <#AnyObject!#>, success: <#((AFHTTPRequestOperation!, AnyObject!) -> Void)!##(AFHTTPRequestOperation!, AnyObject!) -> Void#>, failure: <#((AFHTTPRequestOperation!, NSError!) -> Void)!##(AFHTTPRequestOperation!, NSError!) -> Void#>)

        var anyOb:AnyObject!
        
        client.GET(url, parameters: nil,success: {(operation: AFHTTPRequestOperation!, result: AnyObject!) ->Void in
                NSLog("good")
            }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
//                NSLog("failed to fetch current user %@", error)
            }
        )
    }
//
//    func client() -> LIALinkedInHttpClient {
//        var application: LIALinkedInApplication = LIALinkedInApplication.applicationWithRedirectURL("http://www.ancientprogramming.com/", clientId: LINKEDIN_CLIENT_ID, clientSecret: LINKEDIN_CLIENT_SECRET, state: "DCEEFWF45453sdffef424", grantedAccess: ["r_basicprofile"])
//        return LIALinkedInHttpClient.clientForApplication(application, presentingViewController: nil)
//    }


}

