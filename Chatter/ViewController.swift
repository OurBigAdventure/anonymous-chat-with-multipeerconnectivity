//
//  ViewController.swift
//  Chatter
//
//  Created by Chris Brown on 2/16/15.
//  Copyright (c) 2015 Chris Brown. All rights reserved.
//

import UIKit
import SpriteKit
import CoreData
import Foundation
import MultipeerConnectivity

class ViewController: UIViewController {

  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var thoughtButton: UIButton!
  @IBOutlet var textViewTopConstraint: NSLayoutConstraint!
  var isSending = false
  let colorPicker = UIView()
  var fontList = [String]()
  let chatterBoxClient = MultiPeerConnectivityManager.sharedInstance()
  var messages = [String:String]()
  var animatedTextViews = [String:UITextView]()
  var currentSetting: Settings!
  let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
  var managedContext: NSManagedObjectContext?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    managedContext = appDelegate.managedObjectContext!
    
    let fetchRequest = NSFetchRequest(entityName: "Settings")
    fetchRequest.fetchLimit = 1
    var error: NSError? = nil
    var fetchedResults = managedContext!.executeFetchRequest(fetchRequest, error: &error) as [Settings]
    if fetchedResults.first == nil {
      let entity = NSEntityDescription.entityForName("Settings", inManagedObjectContext: managedContext!)
      currentSetting = Settings(entity: entity!, insertIntoManagedObjectContext: managedContext!)
      self.setDefaultColor()
    } else {
      currentSetting = fetchedResults.first
      if countElements(currentSetting.color) < 6 {
        self.setDefaultColor()
      }
    }
    
    self.view.backgroundColor = hexStringToUIColor(currentSetting.color)

    UIApplication.sharedApplication().idleTimerDisabled = true
    
    textView.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.4)
    textView.alpha = 0.0
    textView.hidden = true
    textView.delegate = self
    textView.layer.cornerRadius = 5.0
    
    self.view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: "endEditing:"))
    let sendGesture = UISwipeGestureRecognizer(target: self, action: "sendThought")
    sendGesture.direction = UISwipeGestureRecognizerDirection.Up
    textView.addGestureRecognizer(sendGesture)
    
    let showColorsGesture = UISwipeGestureRecognizer(target: self, action: "showColorPicker")
    showColorsGesture.direction = UISwipeGestureRecognizerDirection.Right
    self.view.addGestureRecognizer(showColorsGesture)
    
    let hideColorsGesture = UISwipeGestureRecognizer(target: self, action: "hideColorPicker")
    hideColorsGesture.direction = UISwipeGestureRecognizerDirection.Left
    self.view.addGestureRecognizer(hideColorsGesture)
    
    chatterBoxClient.delegate = self
    chatterBoxClient.startAdvertizing()
    chatterBoxClient.startBrowsing()
    
    self.createColorSwitcher()
    
    var familyNames = UIFont.familyNames() as [String]
    for fontFamily in familyNames {
      let family = UIFont.fontNamesForFamilyName(fontFamily) as [String]
      for font in family {
        fontList.append(font)
      }
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func viewDidAppear(animated: Bool) {
  }
  
  @IBAction func newThought(sender: UIButton) {
    isSending = false
    textView.text = ""
    textView.hidden = false
    textView.becomeFirstResponder()
    
    textViewTopConstraint.constant = (self.view.frame.size.height / 3) - textView.frame.size.height
    UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 10.0, options: .CurveEaseOut, animations: { () -> Void in
      self.textView.alpha = 1.0
      self.view.layoutIfNeeded()
    }, completion: nil)
  }
  
  func sendThought() {
    let textToSend = textView.text
    if textToSend != "" {
      chatterBoxClient.stopAdvertizing()
      chatterBoxClient.setMessage(textToSend)
      delay(seconds: 1.0) { () -> () in
        self.chatterBoxClient.startAdvertizing()
      }
      
//      println("Send: \(textToSend)")
      isSending = true
      // Animate the sending of the text message
      let sendAnimation = CAAnimationGroup()
      sendAnimation.beginTime = CACurrentMediaTime()
      sendAnimation.duration = 0.5
      sendAnimation.fillMode = kCAFillModeBackwards
      
      let sendUp = CABasicAnimation(keyPath: "position.y")
      sendUp.fromValue = textView.layer.position.y
      sendUp.toValue = -textView.layer.frame.height
      
      let scaleDown = CABasicAnimation(keyPath: "transform.scale")
      scaleDown.fromValue = 1.0
      scaleDown.toValue = 0.5
      
      let fadeOut = CABasicAnimation(keyPath: "opacity")
      fadeOut.fromValue = 0.4
      fadeOut.toValue = 0.0
      
      sendAnimation.animations = [sendUp, scaleDown, fadeOut]
      textView.layer.addAnimation(sendAnimation, forKey: nil)
      delay(seconds: 0.3) { () -> () in
        self.textView.text = ""
        self.textView.hidden = true
        self.textView.resignFirstResponder()
      }
    } else {
      self.textView.resignFirstResponder()
    }
  }
  
  // MARK: Animations

  func floatLeft(id: String) {
    var fullMessage = messages[id] as String?
    if fullMessage == nil || fullMessage == ""{
      return
    }
    
    if animatedTextViews[id] != nil {
      return
    }

    let characterCount = Double(countElements(fullMessage!))
    let randomValue = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
    let randomAlpha = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
    let scale = ceil(characterCount / 23.0)
    let fontHeight = CGFloat(60.0 * randomValue)
    
    let newMessage = UITextView()
    newMessage.backgroundColor = UIColor.clearColor()
    newMessage.font = UIFont(name: fontList[Int(arc4random_uniform(UInt32(fontList.count)))], size: fontHeight)
    newMessage.text = fullMessage
    newMessage.textAlignment = .Left
    newMessage.textColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: randomAlpha)
    let newSize = newMessage.sizeThatFits(CGSizeMake((view.frame.size.width * 0.8), CGFloat(MAXFLOAT)))
    var yValue = (view.frame.size.height - newSize.height - 46.0) * randomValue
    if yValue < 25.0 {
      yValue += 25.0
    }
    newMessage.frame = CGRect(x: view.frame.size.width, y: yValue, width: newSize.width, height: newSize.height)
    
    animatedTextViews.updateValue(newMessage, forKey: id)
    self.view.addSubview(newMessage)

    let layer = newMessage.layer

    let messageSpeed = Double(15.0 * randomValue) / Double(layer.frame.origin.x + layer.frame.size.width)
    let duration: NSTimeInterval = Double(layer.frame.origin.x + layer.frame.size.width) * messageSpeed
    
    let messageMove = CABasicAnimation(keyPath: "position.x")
    messageMove.duration = duration
    messageMove.toValue = -layer.bounds.width / 2
    messageMove.delegate = self
    messageMove.setValue("message", forKey: "name")
    messageMove.setValue(id, forKey: "id")
    messageMove.setValue(layer, forKey: "layer")
    
    layer.addAnimation(messageMove, forKey: nil)
  }
  
  // MARK: - Animation Delegate Methods
  
  override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
    if let name = anim.valueForKey("name") as? String {
      if name == "message" {
        var messageKeys = messages.keys.array
        let id = anim.valueForKey("id") as String
        let oldView = animatedTextViews[id]
        oldView!.removeFromSuperview()
        animatedTextViews[id] = nil
        let messageDate = NSDate(timeIntervalSince1970: (id as NSString).doubleValue)
        let messageAge = NSDate().timeIntervalSinceDate(messageDate)
        if messageAge > 120 {
          removeMessage(id)
          return
        }
        if contains(messageKeys, id) {
          delay(seconds: 0.5, { () -> () in
            self.floatLeft(id)
          })
        }
      }
    }
  }
  
  func setDefaultColor() {
    var error: NSError? = nil
    currentSetting.color = "0099CC"
    managedContext!.save(&error)
    if error != nil {
      println(error)
    }
  }
  
  func setColor(sender: UIButton) {
    var error: NSError? = nil
    currentSetting.color = sender.accessibilityValue
    managedContext!.save(&error)
    if error != nil {
      println(error)
    }
    self.view.backgroundColor = hexStringToUIColor(currentSetting.color)
    self.colorPicker.backgroundColor = hexStringToUIColor(currentSetting.color)
  }
  
  func createColorSwitcher() {
    colorPicker.frame = CGRectMake(-50.0, 20.0, 50.0, 400.0)
    colorPicker.backgroundColor = hexStringToUIColor(currentSetting.color)
    
    let defaultColorButton = UIButton(frame: CGRectMake(0.0, 0.0, 50.0, 50.0))
    defaultColorButton.backgroundColor = hexStringToUIColor("0099CC")
    defaultColorButton.accessibilityValue = "0099CC"
    defaultColorButton.addTarget(self, action: "setColor:", forControlEvents: .TouchUpInside)
    colorPicker.addSubview(defaultColorButton)

    let darkGreenColorButton = UIButton(frame: CGRectMake(0.0, 50.0, 50.0, 50.0))
    darkGreenColorButton.backgroundColor = hexStringToUIColor("66CC66")
    darkGreenColorButton.accessibilityValue = "66CC66"
    darkGreenColorButton.addTarget(self, action: "setColor:", forControlEvents: .TouchUpInside)
    colorPicker.addSubview(darkGreenColorButton)

    let lightGreenColorButton = UIButton(frame: CGRectMake(0.0, 100.0, 50.0, 50.0))
    lightGreenColorButton.backgroundColor = hexStringToUIColor("66FF33")
    lightGreenColorButton.accessibilityValue = "66FF33"
    lightGreenColorButton.addTarget(self, action: "setColor:", forControlEvents: .TouchUpInside)
    colorPicker.addSubview(lightGreenColorButton)

    let pinkColorButton = UIButton(frame: CGRectMake(0.0, 150.0, 50.0, 50.0))
    pinkColorButton.backgroundColor = hexStringToUIColor("FFCCCC")
    pinkColorButton.accessibilityValue = "FFCCCC"
    pinkColorButton.addTarget(self, action: "setColor:", forControlEvents: .TouchUpInside)
    colorPicker.addSubview(pinkColorButton)

    let purpleColorButton = UIButton(frame: CGRectMake(0.0, 200.0, 50.0, 50.0))
    purpleColorButton.backgroundColor = hexStringToUIColor("CCCCFF")
    purpleColorButton.accessibilityValue = "CCCCFF"
    purpleColorButton.addTarget(self, action: "setColor:", forControlEvents: .TouchUpInside)
    colorPicker.addSubview(purpleColorButton)
    
    let lightPurpleColorButton = UIButton(frame: CGRectMake(0.0, 250.0, 50.0, 50.0))
    lightPurpleColorButton.backgroundColor = hexStringToUIColor("CC3399")
    lightPurpleColorButton.accessibilityValue = "CC3399"
    lightPurpleColorButton.addTarget(self, action: "setColor:", forControlEvents: .TouchUpInside)
    colorPicker.addSubview(lightPurpleColorButton)
    
    let lightBlueColorButton = UIButton(frame: CGRectMake(0.0, 300.0, 50.0, 50.0))
    lightBlueColorButton.backgroundColor = hexStringToUIColor("6699FF")
    lightBlueColorButton.accessibilityValue = "6699FF"
    lightBlueColorButton.addTarget(self, action: "setColor:", forControlEvents: .TouchUpInside)
    colorPicker.addSubview(lightBlueColorButton)
    
    let mudColorButton = UIButton(frame: CGRectMake(0.0, 350.0, 50.0, 50.0))
    mudColorButton.backgroundColor = hexStringToUIColor("CC6633")
    mudColorButton.accessibilityValue = "CC6633"
    mudColorButton.addTarget(self, action: "setColor:", forControlEvents: .TouchUpInside)
    colorPicker.addSubview(mudColorButton)
    
    self.view.addSubview(colorPicker)
  }
  
  func showColorPicker() {
    UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .CurveEaseOut, animations: { () -> Void in
      self.colorPicker.frame.origin.x = -5.0
    }, completion: nil)
  }
  
  func hideColorPicker() {
    UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .CurveEaseIn, animations: { () -> Void in
      self.colorPicker.frame.origin.x = -50.0
    }, completion: nil)
  }
}

// MARK: - Global Functions

// A delay function
func delay(#seconds: Double, completion:()->()) {
  let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64( Double(NSEC_PER_SEC) * seconds ))
  
  dispatch_after(popTime, dispatch_get_main_queue()) {
    completion()
  }
}

// MARK: UIColor from web hex value
func hexStringToUIColor(hex:String) -> UIColor {
  var cString:String = hex.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet() as NSCharacterSet).uppercaseString
  
  if (cString.hasPrefix("#")) {
    cString = cString.substringFromIndex(advance(cString.startIndex, 1))
  }
  
  if (countElements(cString) != 6) {
    return UIColor.grayColor()
  }
  
  var rgbValue:UInt32 = 0
  NSScanner(string: cString).scanHexInt(&rgbValue)
  
  return UIColor(
    red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
    green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
    blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
    alpha: CGFloat(1.0)
  )
}

// Generate a random integer
func randomInt(range: Range<UInt32>) -> UInt32 {
  return range.startIndex + arc4random_uniform(range.endIndex - range.startIndex + 1)
}

// MARK: - Extensions
// MARK:
// MARK: UITextView Delegate
extension ViewController: UITextViewDelegate {
  func textViewDidEndEditing(textView: UITextView) {
    if !isSending {
//      println("Delete: \(textView.text)")
      self.textViewTopConstraint.constant = 150.0
      UIView.animateWithDuration(0.8, delay: 0.0, options: .CurveEaseIn, animations: { () -> Void in
        textView.alpha = 0.0
        self.view.layoutIfNeeded()
        }) { _ in
          textView.text = ""
          textView.hidden = true
          self.textViewTopConstraint.constant = 8.0
      }
    }
  }
}

// MARK: MultiPeerConnectivityManager Delegate
extension ViewController: MultiPeerConnectivityManagerDelegate {
  func addMessage(id: String, message: String, name: String?) {
    if messages[id] == nil {
//      println("Adding Message...")
      var fullMessage = message
      if name != nil && name != "" {
        fullMessage = message.stringByAppendingString("\n - \(name!)")
      }
      messages.updateValue(fullMessage, forKey: id)
      floatLeft(id)
//      println("Messages Array: \(messages)")
    }
  }
  
  func removeMessage(id: String) {
//    println("Removing Message: \(id)")
    messages.removeValueForKey(id)
  }
}
