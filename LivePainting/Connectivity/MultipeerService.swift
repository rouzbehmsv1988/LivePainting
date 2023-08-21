//
//  MultipeerService.swift
//  LivePainting
//
//  Created by rouzbeh on 21.08.23.
//

import Foundation
import MultipeerConnectivity

enum ConnectionStatus: String {
    case connected = "Connected"
    case disconnected = "Disconnected"
    case notFired = "Waiting for Devices"
}

enum FileStatus {
    case notStarted
    case startedReceiving
    case donwnloadCompleted
    case failed
}

struct MultipeerData {
    var status: ConnectionStatus = .notFired
    var fileStatus: FileStatus = .notStarted
    var connectedDevices: [String] = []
    var lines: [Line] = []
}


class MultipeerService: NSObject, ObservableObject {
    @Published var peerData = MultipeerData()
    private var peerID: MCPeerID!
  
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    lazy var session: MCSession = {
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    func setupPeerWithDisplayName(displayName: String) {
        peerID = MCPeerID(displayName: displayName)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "my-test")
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "my-test")
       
        advertiser?.delegate = self
        browser?.delegate = self
        startBrowsing()
        startAdvertising()
    }
    
    private var activePeers: [MCPeerID] = []
    override init() {
        super.init()
    }
    

    func startAdvertising() {
        advertiser?.startAdvertisingPeer()
       
    }
    func startBrowsing() {
        browser?.startBrowsingForPeers()
  
    }

    
    func stopBrowser() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }


    // MARK: - MCSessionDelegate
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        var status: ConnectionStatus = .notFired
        DispatchQueue.global(qos: .background).async { [weak self] in
            switch state {
            case .connected:
                print("connected")
                status = .connected
                // Add the connected peer to the list of active peers
                if !(self?.activePeers ?? []).contains(peerID) {
                    self?.activePeers.append(peerID)
                    DispatchQueue.main.async { [weak self] in
                        print("connected Devices \(peerID.displayName)")
                        self?.peerData.connectedDevices.append(peerID.displayName)
                       _ = self?.peerData.connectedDevices.filter ({ name in
                            !name.contains("iphone")
                        })
                        self?.peerData.status = status
                    }
                }

               
            case .notConnected:
      
                // Remove the disconnected peer from the list of active peers
                if let index = self?.activePeers.firstIndex(of: peerID) {
                    status = .disconnected
                    print(" not connected")
                    DispatchQueue.main.async { [weak self] in
                        self?.activePeers.remove(at: index)
                        self?.peerData.status = status
                    }
                }
            default:
                break
            }

            
        }
    }
    
    
    func updateFileStaus(status: FileStatus, patientName: String? = "") {
        DispatchQueue.main.async { [weak self] in
            self?.peerData.fileStatus = status
        }
    }
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        updateFileStaus(status: .startedReceiving)
        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                let lines = try JSONDecoder().decode([Line].self, from: data)
                // Do something with the received lines
                DispatchQueue.main.async { [weak self] in
                    self?.peerData.lines = lines
                }
            } catch {
                print("Error receiving lines data: \(error.localizedDescription)")
            }
        }

    }

    func sendLines() {
        do {
            let jsonData = try JSONEncoder().encode(peerData.lines)
            try session.send(jsonData, toPeers: activePeers, with: .reliable)
        } catch {
            print("Error sending lines data: \(error.localizedDescription)")
        }
    }

}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("Found peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost peer: \(peerID.displayName)")
    }
}

extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used in this example
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used in this example
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used in this example
    }
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
    }
}
