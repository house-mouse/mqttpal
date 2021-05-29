//
//  ViewController.swift
//

import UIKit
import AVFoundation
import CoreLocation
import SwiftMQTT
import CoreData


class ViewController: UIViewController, MQTTSessionDelegate {
    
    var mqttSession: MQTTSession!
    var container: NSPersistentContainer!

    @IBOutlet var textView: UITextView!
    @IBOutlet var channelTextField: UITextField!
    @IBOutlet var messageTextField: UITextField!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        channelTextField = UITextField (frame:CGRect(x:10, y:10, width:300, height:20));
        self.view.addSubview(channelTextField)
        
        textView = UITextView(frame:CGRect(x:10, y:50, width:600, height:200));
        self.view.addSubview(textView)

        print("View controller DidLoad")
        establishConnection()
        
        
        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        button.backgroundColor = .green
/*
        let image = UIImage.fontAwesomeIcon(name: .coffee, textColor: UIColor.black, size: CGSize(width: 40, height: 40))
 
        
        //let icon = UIImage(named: "bmiCalculator")!
        let icon = UIImage.fontAwesomeIcon(
            name:.github,
            style: .brands,
            textColor: .black,
            size:CGSize(width:4000, height:4000))
        
        button.setImage(icon, for: .normal)
 */
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 0)
        
        
        button.setTitle("Test On", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        self.view.addSubview(button)

        
        
        
        
        let button2 = UIButton(frame: CGRect(x: 100, y: 150, width: 100, height: 50))
        button2.backgroundColor = .red
/*
        let image = UIImage.fontAwesomeIcon(name: .coffee, textColor: UIColor.black, size: CGSize(width: 40, height: 40))
 
        
        //let icon = UIImage(named: "bmiCalculator")!
        let icon = UIImage.fontAwesomeIcon(
            name:.github,
            style: .brands,
            textColor: .black,
            size:CGSize(width:4000, height:4000))
        
        button.setImage(icon, for: .normal)
 */
        button2.imageView?.contentMode = .scaleAspectFit
        button2.imageEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 0)
        
        
        button2.setTitle("Test Off", for: .normal)
        button2.addTarget(self, action: #selector(buttonActionOff), for: .touchUpInside)
        
        self.view.addSubview(button2)
        
        
        
    }

    @objc func buttonAction(sender: UIButton!) {
      print("Button tapped")

        let json = ["POWER" : "OFF"]
//        let data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let topic = "cmnd/livingroomtorch/POWER";
        let data: Data? = "ON".data(using: .utf8) // non-nil

        mqttSession.publish(data!, in: topic, delivering: .atLeastOnce, retain: false) { error in
            if error == .none {
                print("Published data in \(topic)!")
            } else {
                print(error.description)
            }
        }
    }

        @objc func buttonActionOff(sender: UIButton!) {
          print("Button tapped")

//            let json = ["POWER" : "OFF"]
    //        let data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            let topic = "cmnd/livingroomtorch/POWER";
            let data: Data? = "OFF".data(using: .utf8) // non-nil

            mqttSession.publish(data!, in: topic, delivering: .atLeastOnce, retain: false) { error in
                if error == .none {
                    print("Published data in \(topic)!")
                } else {
                    print(error.description)
                }
            }

    }
    
    
    func establishConnection() {
        let host = "mqtt.home"
        let port: UInt16 = 1883
        let clientID = self.clientID()
        
        mqttSession = MQTTSession(host: host, port: port, clientID: clientID, cleanSession: true, keepAlive: 15, useSSL: false)
        mqttSession.delegate = self
        appendStringToTextView("Trying to connect to \(host) on port \(port) for clientID \(clientID)")
        
        mqttSession.connect { (error) in
            if error == .none {
                self.appendStringToTextView("Connected.")
                self.subscribeToChannel()
            } else {
                self.appendStringToTextView("Error occurred during connection:")
                self.appendStringToTextView(error.description)
            }
        }
    }
    
    func subscribeToChannel() {
        let channel = "stat/#"
        mqttSession.subscribe(to: channel, delivering: .atLeastOnce) { (error) in
            if error == .none {
                self.appendStringToTextView("Subscribed to \(channel)")
            } else {
                self.appendStringToTextView("Error occurred during subscription:")
                self.appendStringToTextView(error.description)
            }
        }
    }
    
    func appendStringToTextView(_ string: String) {
        textView.text = "\(textView.text ?? "")\n\(string)"
        let range = NSMakeRange(textView.text.count - 1, 1)
        textView.scrollRangeToVisible(range)
    }
    
    // MARK: - MQTTSessionDelegates
    
    func mqttDidReceive(message: MQTTMessage, from session: MQTTSession) {
        appendStringToTextView("data received on topic \(message.topic) message \(message.stringRepresentation ?? "<>")")
    }
    
    func mqttDidDisconnect(session: MQTTSession, error: MQTTSessionError) {
        appendStringToTextView("Session Disconnected.")
        if error != .none {
            appendStringToTextView(error.description)
        }
    }
    
    func mqttDidAcknowledgePing(from session: MQTTSession) {
        appendStringToTextView("Keep-alive ping acknowledged.")
    }
    
    // MARK: - IBActions
    
    @IBAction func resetButtonPressed(_ sender: AnyObject) {
        textView.text = nil
        channelTextField.text = nil
        messageTextField.text = nil
        establishConnection()
    }
    
    @IBAction func sendButtonPressed(_ sender: AnyObject) {
        
        guard let channel = channelTextField.text, let message = messageTextField.text,
            !channel.isEmpty && !message.isEmpty
            else { return }
        
        let data = message.data(using: .utf8)!
        mqttSession.publish(data, in: channel, delivering: .atMostOnce, retain: false) { (error) in
            switch error {
            case .none:
                self.appendStringToTextView("Published \(message) on channel \(channel)")
            default:
                self.appendStringToTextView("Error Occurred During Publish:")
                self.appendStringToTextView(error.description)
            }
        }
    }
    
    // MARK: - Utilities
    
    func clientID() -> String {
        
        let userDefaults = UserDefaults.standard
        let clientIDPersistenceKey = "clientID"
        let clientID: String
        
        if let savedClientID = userDefaults.object(forKey: clientIDPersistenceKey) as? String {
            clientID = savedClientID
        } else {
            clientID = randomStringWithLength(5)
            userDefaults.set(clientID, forKey: clientIDPersistenceKey)
            userDefaults.synchronize()
        }
        
        return clientID
    }
    
    // http://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
    func randomStringWithLength(_ len: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        var randomString = String()
        for _ in 0..<len {
            let length = UInt32(letters.count)
            let rand = arc4random_uniform(length)
            let index = String.Index(encodedOffset: Int(rand))
            randomString += String(letters[index])
        }
        return String(randomString)
    }
    
}
