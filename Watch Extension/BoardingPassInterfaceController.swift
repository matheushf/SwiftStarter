//
//  BoardingPassInterfaceController.swift
//  AirAber
//
//  Created by Matheus on 08/03/17.
//  Copyright © 2017 Mic Pringle. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class BoardingPassInterfaceController: WKInterfaceController {
  
  @IBOutlet var originLabel: WKInterfaceLabel!
  @IBOutlet var destinationLabel: WKInterfaceLabel!
  @IBOutlet var boardingPassImage: WKInterfaceImage!
  
  var session: WCSession? {
    didSet {
      if let session = session {
        session.delegate = self
        session.activate()
      }
    }
  }
  
  var flight: Flight? {
    didSet {
      if let flight = flight {
        originLabel.setText(flight.origin)
        destinationLabel.setText(flight.destination)
        
        if let _ = flight.boardingPass {
          showBoardingPass()
        }
      }
    }
  }
  
  override func awake(withContext context: Any?) {
    super.awake(withContext: context)
    
    if WCSession.isSupported() {
      let wcsession = WCSession.default()
      wcsession.delegate = self
      wcsession.activate()
      wcsession.sendMessage(["update": "list"], replyHandler: { (dict) -> Void in
        print("InterfaceController session response: \(dict)")
      }, errorHandler: { (error) -> Void in
        print("InterfaceController session error: \(error)")
      })
    }
    
    if let flight = context as? Flight { self.flight = flight }
  }
  
  override func didAppear() {
    super.didAppear()
    
    if let flight = flight, flight.boardingPass == nil && WCSession.isSupported() {
      
      if WCSession.default().isReachable {
        
        let session = WCSession.default()
        
        session.sendMessage(["reference": flight.reference], replyHandler: { (response) -> Void in
          // 4
          if let boardingPassData = response["boardingPassData"] as? NSData, let boardingPass = UIImage(data: boardingPassData as Data) {
            // 5
            flight.boardingPass = boardingPass
            
            DispatchQueue.main.async {
              self.showBoardingPass()
            }
            
          }
        }, errorHandler: { (error) -> Void in
          // 6
          print(error)
        })
      }
    }
  }
  
  private func showBoardingPass() {
    boardingPassImage.stopAnimating()
    boardingPassImage.setWidth(120)
    boardingPassImage.setHeight(120)
    boardingPassImage.setImage(flight?.boardingPass)
  }
  
}

extension BoardingPassInterfaceController: WCSessionDelegate {
  func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
