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

class ViewController: UIViewController {
    
    var client:LIALinkedInHttpClient?
    
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
        
        self.client.getAuthorizationCode({(code: String) in        self.client.getAccessToken(code, success: {(accessTokenData: [NSObject: AnyObject]) in            var accessToken: String = accessTokenData.objectForKey("access_token")
            self.requestMeWithToken(accessToken)
            
            }, failure: {(error: NSError) in            NSLog("Quering accessToken failed %@", error)
                
        })
            
            }, cancel: {        NSLog("Authorization was cancelled by user")
                
            }, failure: {(error: NSError) in        NSLog("Authorization failed %@", error)
                
        })
    }
    
    func requestMeWithToken(accessToken: String) {
        self.client.GET("https://api.linkedin.com/v1/people/~?oauth2_access_token=\(accessToken)&format=json", parameters: nil, success: {(operation: AFHTTPRequestOperation, result: [NSObject: AnyObject]) in        NSLog("current user %@", result)
            
            }, failure: {(operation: AFHTTPRequestOperation, error: NSError) in        NSLog("failed to fetch current user %@", error)
                
        })
    }
    
    func client() -> LIALinkedInHttpClient {
        var application: LIALinkedInApplication = LIALinkedInApplication.applicationWithRedirectURL("http://www.ancientprogramming.com/", clientId: LINKEDIN_CLIENT_ID, clientSecret: LINKEDIN_CLIENT_SECRET, state: "DCEEFWF45453sdffef424", grantedAccess: ["r_basicprofile"])
        return LIALinkedInHttpClient.clientForApplication(application, presentingViewController: nil)
    }


}

