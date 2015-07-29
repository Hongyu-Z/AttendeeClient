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
import CoreBluetooth
import CoreLocation
import MultipeerConnectivity

let LINKEDIN_CLIENT_ID: String = "75qpogf438frch"
let LINKEDIN_CLIENT_SECRET: String = "6G2SveM77DOAiDpJ"


class ViewController: UIViewController, CBCentralManagerDelegate, CLLocationManagerDelegate,MCNearbyServiceBrowserDelegate, MCSessionDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    
    var beaconRegion:CLBeaconRegion!
    var bluetoothManager:CBCentralManager!
    var locationManager:CLLocationManager!
    var browser:MCNearbyServiceBrowser!
    var localPeerID:MCPeerID!
    var session:MCSession!
    var peerSet = Set<MCPeerID>()
    var scanningForPeer,scanningForBeacons,ranging,didSendContactInfo:Bool!
    
    var client:LIALinkedInHttpClient = {
        var application:LIALinkedInApplication = LIALinkedInApplication.applicationWithRedirectURL("http://www.ancientprogramming.com/", clientId: LINKEDIN_CLIENT_ID, clientSecret: LINKEDIN_CLIENT_SECRET, state: "DCEEFWF45453sdffef424", grantedAccess: ["r_basicprofile"]) as! LIALinkedInApplication
        return LIALinkedInHttpClient(forApplication: application,presentingViewController: nil)
    }()
    var delegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.scanningForBeacons=false
        self.scanningForPeer=false
        self.ranging=false
        self.didSendContactInfo=false
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        var uuID = NSUUID()
        self.beaconRegion = CLBeaconRegion(proximityUUID: uuID, identifier: "AttendeeSender")
        self.localPeerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        self.browser = MCNearbyServiceBrowser(peer: self.localPeerID, serviceType: "cl-attendees")
        self.browser.delegate = self
        
        if(CLLocationManager.isMonitoringAvailableForClass(CLBeaconRegion)){
            println("start monitoring")
            self.statusLabel.text = "start monitoring"
            self.locationManager.startMonitoringForRegion(self.beaconRegion)
            self.locationManager.requestStateForRegion(self.beaconRegion)
        } else {
            println("does not support monitoring")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didTapConnectWithLinkedIn(sender: AnyObject) {
        
        client.getAuthorizationCode(
            {(authCode:String!)->Void in self.client.getAccessToken(authCode,
                success: { (accessTokenData: [NSObject: AnyObject]!) in
                    var accessToken:String = accessTokenData["access_token"] as! String
//                    NSLog(accessToken)
                    self.requestMeWithToken(accessToken)
                },
                failure: {(error: NSError!)->Void in NSLog("Quering accessToken failed \(error)")})
            },
            cancel: {NSLog("Authorization was cancelled by user")},
            failure: {(error: NSError!)->Void in NSLog("Authorization failed \(error)")})
        
    }
    
    func requestMeWithToken(accessToken: String) {
        let url:String! = "https://api.linkedin.com/v1/people/~?oauth2_access_token=\(accessToken)&format=json"

        var anyOb:AnyObject!
        
        client.GET(url, parameters: nil,success: {(operation: AFHTTPRequestOperation!, result: AnyObject!) ->Void in
            
            var dict = self.convertNSDicToSwiftDic(result as! NSDictionary)

            self.statusLabel.text = "logged in profile"
            var firstName = dict["firstName"] as! String
            var lastName = dict["lastName"] as! String
            var headline = dict["headline"] as! String
            var id = dict["id"] as! String
            var newAttendee = Attendee(firstName: firstName, lastName: lastName, headLine: headline, attendeeID: id)
            var data = NSKeyedArchiver.archivedDataWithRootObject(newAttendee)
            NSUserDefaults.standardUserDefaults().setObject(data, forKey: "me")
            self.startScanningForPeer()

            }, failure: {(operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
                NSLog("failed to fetch current user: \(error.description)")
            }
        )
    }
    
    func startScanningForPeer(){
        self.browser.startBrowsingForPeers()
        self.scanningForPeer = true
    }
    
    func stopScanningForPeer(){
        self.browser.stopBrowsingForPeers()
        self.scanningForPeer = false
    }
    
    func convertNSDicToSwiftDic (ocDict: NSDictionary) -> Dictionary<String, AnyObject!>{
        var swiftDict : Dictionary<String,AnyObject!> = Dictionary<String,AnyObject!>()
        for key : AnyObject in ocDict.allKeys {
            let stringKey = key as! String
            if let keyValue: AnyObject = ocDict.valueForKey(stringKey){
                swiftDict[stringKey] = keyValue
            }
        }
        return swiftDict
    }
    
    func sendMeToPeer(peer:MCPeerID){
        var me : NSData = NSUserDefaults.standardUserDefaults().objectForKey("me") as! NSData
        var error : NSError?
        if(self.session.sendData(me, toPeers: [peer], withMode: MCSessionSendDataMode.Reliable, error:&error) ){
            self.browser.stopBrowsingForPeers()
            self.locationManager.stopRangingBeaconsInRegion(self.beaconRegion)
            self.ranging = false
            
        } else {
            println("error when sending data to peer \(error)")
        }
    }
    
//MARK: implementing CBCentralManagerDelegate
    
    /*!
    *  @method centralManagerDidUpdateState:
    *
    *  @param central  The central manager whose state has changed.
    *
    *  @discussion     Invoked whenever the central manager's state has been updated. Commands should only be issued when the state is
    *                  <code>CBCentralManagerStatePoweredOn</code>. A state below <code>CBCentralManagerStatePoweredOn</code>
    *                  implies that scanning has stopped and any connected peripherals have been disconnected. If the state moves below
    *                  <code>CBCentralManagerStatePoweredOff</code>, all <code>CBPeripheral</code> objects obtained from this central
    *                  manager become invalid and must be retrieved or discovered again.
    *
    *  @see            state
    *
    */
    func centralManagerDidUpdateState(central: CBCentralManager!){
        var statusString = "nothing"
        switch(central.state){
        case CBCentralManagerState.PoweredOff:
            statusString = "CBCentralManager Powered off"
            break
        case CBCentralManagerState.PoweredOn:
            statusString = "CBCentralManager Powered on"
            break
        case CBCentralManagerState.Resetting:
            statusString = "CBCentralManager Resetting"
            break
        case CBCentralManagerState.Unauthorized:
            statusString = "CBCentralManager Unauthorized"
            break
        case CBCentralManagerState.Unsupported:
            statusString = "CBCentralManager Unsupported"
            break
        case CBCentralManagerState.Unknown:
            statusString = "CBCentralManager Unknown"
            break
        }
        self.statusLabel.text = statusString
        println(statusString)
    }
    
//MARK: implementing MCNearbyServiceBrowserDelegate
    // Found a nearby advertising peer
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!){
        println("found peer \(peerID.displayName)")
        self.statusLabel.text="found peer \(peerID.displayName)"
        self.peerSet.insert(peerID)
        self.session = MCSession(peer: self.localPeerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        self.session.delegate = self
        
        self.browser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 5)
    }
    
    // A nearby peer has stopped advertising
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!){
        println("MCNearbyServiceBrowser: peer lost")
    }
    
//MARK: implementing MCSessionDelegate
    // Remote peer changed state
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState){
        switch(state){
        case MCSessionState.Connected:
            println("MCSession didChangeState: Connected")
            self.statusLabel.text = "connected"
            self.sendMeToPeer(peerID)
            break
        case MCSessionState.Connecting:
            println("MCSession didChangeState: Connecting")
            self.statusLabel.text = "connecting"
            break
        case MCSessionState.NotConnected:
            println("MCSession didChangeState: Not Connected")
            break
        }
    }
    
    // Received data from remote peer
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!){
        println("MCSession: didReceiveData")
    }
    
    // Received a byte stream from remote peer
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!){
        println("MCSession: didReceiveStream")
    }
    
    // Start receiving a resource from remote peer
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!){
        println("MCSession: didStartReceivingResourceWithNmae")
    }
    
    // Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!){
        println("MCSession: didFinishReceivingResourceWithName")
    }


}

