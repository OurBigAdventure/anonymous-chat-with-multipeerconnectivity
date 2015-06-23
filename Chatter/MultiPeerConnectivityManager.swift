//
//  MultiPeerConnectivityManager.swift
//  Chatter
//
//  Created by Chris Brown on 2/16/15.
//  Copyright (c) 2015 Chris Brown. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol MultiPeerConnectivityManagerDelegate {
  func addMessage(id: String, message: String, name: String?)
  func removeMessage(id: String)
  func incrementBlockCount()
}

@objc class MultiPeerConnectivityManager: NSObject {
  
  // MARK: Properties
  var delegate: MultiPeerConnectivityManagerDelegate?
  var peerID: MCPeerID?
  var session: MCSession?
  var browser: MCBrowserViewController?
  let serviceType = "oba-chatterbox"
  var broadcaster: MCNearbyServiceAdvertiser?
  var serviceBrowser: MCNearbyServiceBrowser?
  var messages = [String:MCPeerID]()
  var message = "My first chatter..."
  var blockUsers = [String]()
  
  // MARK: Methods
  override init() {
    super.init()
//    peerID = MCPeerID(displayName: "\(NSDate().timeIntervalSince1970)")
    peerID = MCPeerID(displayName: UIDevice.currentDevice().identifierForVendor.UUIDString)
    session = MCSession(peer: peerID)
    session!.delegate = self
  }
  
  class func sharedInstance() -> MultiPeerConnectivityManager {
    return MultiPeerConnectivityManagerSingletonGlobal
  }

  func myMessage(message: String) {
    if message != "" {
//      peerID = MCPeerID(displayName: "\(NSDate().timeIntervalSince1970)")
      peerID = MCPeerID(displayName: UIDevice.currentDevice().identifierForVendor.UUIDString)
      session = MCSession(peer: peerID)
      self.message = message
    }
  }
  
  func startAdvertizing() {
    let discoveryDictionary = ["date": "\(NSDate().timeIntervalSince1970)", "message": message, "name": ""];
    broadcaster = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discoveryDictionary, serviceType: serviceType)
    broadcaster!.delegate = self
    broadcaster!.startAdvertisingPeer()
//    println("Now Advertizing: \(broadcaster!.serviceType)")
  }
  
  func stopAdvertizing() {
    broadcaster!.stopAdvertisingPeer()
//    println("Stopped Advertizing: \(broadcaster!.serviceType)")
    broadcaster = nil
  }
  
  func startBrowsing() {
    serviceBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
    serviceBrowser!.delegate = self
    serviceBrowser!.startBrowsingForPeers()
//    println("Now Browsing: \(serviceBrowser!.serviceType)")
  }

  func stopBrowsing() {
    serviceBrowser!.stopBrowsingForPeers()
//    println("Stopped Browsing: \(serviceBrowser!.serviceType)")
    serviceBrowser = nil
  }
  
  func blockPeer(name: String) -> Bool {
    if messages[name]!.displayName != self.peerID!.displayName {
      self.blockUsers.append(messages[name]!.displayName)
      serviceBrowser?.invitePeer(messages[name], toSession: self.session, withContext: nil, timeout: 1.0)
      delegate?.removeMessage(name)
      return true
    }
    return false
  }
}

let MultiPeerConnectivityManagerSingletonGlobal = MultiPeerConnectivityManager()

// MARK: - Extensions
// MARK:

// MARK: MCNearbyServiceAdvertizer Delegate
extension MultiPeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {
  func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
    // this is a notice that we've been blocked
    delegate?.incrementBlockCount()
    // refuse all connections, we don't need them
    invitationHandler(false, nil)
  }
  
  func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
//    println("Did not start advertizing: \(error)")
  }
}

// MARK: MCSession Delegate
extension MultiPeerConnectivityManager: MCSessionDelegate {
  func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
    // We don't receive data
  }
  
  func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
    // We don't accept resources
  }
  
  func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
    // We don't accept resources
  }
  
  func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
    // We don't accept streams
  }
  
  func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
    // We don't accept connections
  }
  
  func session(session: MCSession!, didReceiveCertificate certificate: [AnyObject]!, fromPeer peerID: MCPeerID!, certificateHandler: ((Bool) -> Void)!) {
    // We don't accept connections
  }
}

// MARK: MCNearbyServiceBrowser Delegate
extension MultiPeerConnectivityManager: MCNearbyServiceBrowserDelegate {
  func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
    if !contains(self.blockUsers, peerID.displayName as String) {
      messages.updateValue(peerID, forKey: info["date"] as! String)
      delegate?.addMessage(info["date"] as! String, message: info["message"] as! String, name: info["name"] as? String)
//      println("Discovered:\npeerID: \(peerID)\ninfo: \(info)")
    }
  }
  
  func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
//    println("Gone: \(peerID.description)")
    var messageKeys = messages.keys
    for key in messageKeys {
      if messages[key] == peerID {
        delegate?.removeMessage(key)
        return
      }
    }
  }
  
  func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
//    println("Did not start browsing: \(error)")
  }
}
