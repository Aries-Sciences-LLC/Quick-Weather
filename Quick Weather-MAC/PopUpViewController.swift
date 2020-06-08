//
//  PopUpViewController.swift
//  Quick Weather-MAC
//
//  Created by Ozan Mirza on 2/9/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Cocoa
import WebKit
import CoreLocation

class PopUpViewController: NSViewController, WKUIDelegate, WKNavigationDelegate, CLLocationManagerDelegate, NSTextFieldDelegate {
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    var lat = Double()
    var lon = Double()
    var locationSent = false
    var autoLocationSelected = true
    var setCity = false
    var initLatLon = CLLocation()
    var currentCities : [String] = []
    var locationGetter : NSProgressIndicator = NSProgressIndicator()
    
    @IBOutlet weak var mainView: WKWebView!
    @IBOutlet weak var exitBtn: NSButton!
    @IBOutlet weak var main_icon: NSImageView!
    @IBOutlet weak var refresBtn: NSButton!
    @IBOutlet weak var locationSelector: NSButton!
    @IBOutlet weak var cityLbl: NSTextField!
    @IBOutlet weak var cityPicker: NSVisualEffectView!
    @IBOutlet weak var citySetter: NSTextField!
    @IBOutlet weak var autoViews: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Weather Content: https://rawcdn.githack.com/ozanmirza1/Quick-Weather/38ecd617ec3f24f821dd45ee72e7160e1b8da9d0/CONTENT/index.html
        // City Names: https://raw.githubusercontent.com/lutangar/cities.json/master/cities.json
        
        locationGetter = NSProgressIndicator()
        locationGetter.frame.size = NSSize(width: 50, height: 50)
        locationGetter.frame.origin = NSPoint(x: (self.view.frame.size.width / 2) - 17.5, y: (self.view.frame.size.height / 2) - 150)
        locationGetter.style = NSProgressIndicator.Style.spinning
        locationGetter.sizeToFit()
        locationGetter.startAnimation(self)
        self.view.addSubview(locationGetter)
        
        self.citySetter.delegate = self
        self.citySetter.focusRingType = NSFocusRingType.none
        
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        cityPicker.wantsLayer = true
        cityPicker.layer?.cornerRadius = 25
        cityPicker.layer?.masksToBounds = true
        cityPicker.frame.origin.y = 0 - cityPicker.frame.size.height
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            self.locationManager.requestLocation() // Front use
            self.locationManager.startUpdatingLocation()
        }
        
        self.view.wantsLayer = true
        
        if CLLocationManager.locationServicesEnabled() == false {
            let bg = NSVisualEffectView(frame: self.view.bounds)
            bg.material = NSVisualEffectView.Material.appearanceBased
            self.view.addSubview(bg)
            
            let prompt = NSView(frame: NSRect(x: 64, y: self.view.frame.size.height + 300, width: bg.frame.size.width - 128, height: 300))
            prompt.wantsLayer = true
            prompt.layer?.backgroundColor = NSColor(red: (244 / 255), green: (66 / 255), blue: (66 / 255), alpha: 1).cgColor
            prompt.layer?.cornerRadius = 25
            prompt.layer?.masksToBounds = true
            bg.addSubview(prompt)
            
            let promptTTL = NSTextView(frame: NSRect(x: 0, y: prompt.frame.size.height - 70, width: prompt.frame.size.width, height: 50))
            promptTTL.string = "Uh-Oh, Location Isn't Available!"
            promptTTL.isEditable = false
            promptTTL.textColor = NSColor.white
            promptTTL.alignment = NSTextAlignment.center
            promptTTL.font = NSFont.systemFont(ofSize: 25)
            promptTTL.drawsBackground = false
            prompt.addSubview(promptTTL)
            
            let promptDescription = NSTextView(frame: NSRect(x: 16, y: 40, width: prompt.frame.size.width - 32, height: 200))
            promptDescription.drawsBackground = false
            promptDescription.textColor = NSColor.lightGray
            promptDescription.alignment = NSTextAlignment.center
            promptDescription.string = "Looks like you turned off your location services, if you would like to find the weather for your location, please go to System Prefrences -> General & Privacy -> Privacy -> Click the lock in the bottom corner, type in password -> Check the enable location services box -> Lock to save -> Relaunch app."
            promptDescription.font = NSFont.systemFont(ofSize: 20)
            prompt.addSubview(promptDescription)
            
            let useCustomLocation = NSButton(frame: NSRect(x: self.view.frame.size.width / 2, y: (bg.frame.size.height / 2) - 182, width: 0, height: 30))
            useCustomLocation.wantsLayer = true
            useCustomLocation.isBordered = false
            useCustomLocation.layer?.backgroundColor = NSColor(red: (66 / 255), green: (66 / 255), blue: (244 / 255), alpha: 1).cgColor
            useCustomLocation.layer?.cornerRadius = useCustomLocation.frame.size.height / 2
            useCustomLocation.layer?.masksToBounds = true
            let pstyle = NSMutableParagraphStyle()
            pstyle.alignment = NSTextAlignment.center
            useCustomLocation.attributedTitle = NSAttributedString(string: "Open System Preferences", attributes: [ NSAttributedString.Key.foregroundColor : NSColor.white, NSAttributedString.Key.paragraphStyle : pstyle ])
            useCustomLocation.font = NSFont.systemFont(ofSize: 25)
            useCustomLocation.alignment = NSTextAlignment.center
            useCustomLocation.action = #selector(self.usingCustomLocation(_:))
            bg.addSubview(useCustomLocation)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.duration = 1
                prompt.animator().frame.origin.y = (bg.frame.size.height / 2) - 150
                useCustomLocation.animator().frame.origin.x = 64
                useCustomLocation.animator().frame.size.width = prompt.frame.size.width
                NSAnimationContext.endGrouping()
            }
        }
    }
    
    @objc func usingCustomLocation(_ sender: NSButton!) {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
        NSApplication.shared.terminate(self)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        return
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lat = locations[0].coordinate.latitude
        lon = locations[0].coordinate.longitude
        initLatLon = CLLocation(latitude: lat, longitude: lon)
        
        if setCity == false {
            setCity = true
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lon)) { (placemarks, error) in
                if error != nil {
                    self.dialogOKCancel(question: "Uh-Oh, can't find city! :(", text: "We can still display the weather for you, but not the city name.")
                } else {
                    guard let placeMark = placemarks?.first else { return }
                    
                    if let city = placeMark.subAdministrativeArea {
                        self.cityLbl.stringValue += city
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 1.0
            self.main_icon.animator().alphaValue = 0
            self.locationGetter.alphaValue = 0
            NSAnimationContext.endGrouping()
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                self.mainView.uiDelegate = self
                self.mainView.navigationDelegate = self
                self.mainView.load(URLRequest(url: URL(string: "https://rawcdn.githack.com/ozanmirza1/Quick-Weather/38ecd617ec3f24f821dd45ee72e7160e1b8da9d0/CONTENT/index.html")!))
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        locationSent = true
        mainView.evaluateJavaScript("getWeatherData(\(lat), \(lon));", completionHandler: nil)
    }
    
    @IBAction func quitApplication(_ sender: NSButton) {
        NSApplication.shared.terminate(self)
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if (obj.object as? NSTextField)! == citySetter {
            citySetter.stringValue = citySetter.stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "/\\"))
            let finder = citySetter.stringValue.replacingOccurrences(of: " ", with: "%20")
            self.autoCompleteCityNames(with: finder, completion: { parsedData in
                self.currentCities = []
                DispatchQueue.main.async {
                    self.autoViews.subviews.forEach { subLbl in subLbl.removeFromSuperview() }
                    var y_pos = self.autoViews.frame.size.height
                    if parsedData != nil {
                        for i in 0..<parsedData!.predictions.count {
                            let subLbl = NSButton(frame: NSRect(x: 0, y: y_pos, width: 375, height: 50))
                            y_pos -= 50
                            subLbl.wantsLayer = true
                            subLbl.layer?.backgroundColor = NSColor.clear.cgColor
                            subLbl.font = NSFont.systemFont(ofSize: 25)
                            subLbl.title = parsedData!.predictions[i].description!
                            subLbl.isBordered = false
                            subLbl.action = #selector(self.setCustomLocation(_:))
                            if subLbl.title.count > 35 {
                                subLbl.font = NSFont.systemFont(ofSize: 20)
                            }
                            self.autoViews.addSubview(subLbl)
                            let divider = NSView(frame: NSRect(x: 0, y: y_pos, width: 375, height: 2))
                            divider.wantsLayer = true
                            divider.layer?.backgroundColor = NSColor.gray.cgColor
                            self.autoViews.addSubview(divider)
                            self.currentCities.append(parsedData?.predictions[i].structuredFormatting?.mainText ?? self.citySetter.stringValue)
                        }
                    }
                }
            })
        }
    }
    
    @objc func setCustomLocation(_ sender: NSButton!) {
        let activityIndicator = NSProgressIndicator()
        activityIndicator.frame.size = NSSize(width: 50, height: 50)
        activityIndicator.frame.origin = NSPoint(x: (self.view.frame.size.width / 2) - 17.5, y: (self.view.frame.size.height / 2) - 17.5)
        activityIndicator.style = NSProgressIndicator.Style.spinning
        activityIndicator.sizeToFit()
        activityIndicator.startAnimation(self)
        self.view.addSubview(activityIndicator)
        
        self.citySetter.stringValue = ""
        self.autoViews.subviews.forEach { (autoCompleter) in autoCompleter.removeFromSuperview() }
        for i in 0..<currentCities.count {
            if sender.title.contains(currentCities[i]) {
                URLSession.shared.dataTask(with: URL(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=" + currentCities[i].forSorting + "&types=address&language=en&sensor=true&key=AIzaSyA8pukmW_of-7QT_Y1FH9MkqZOq4X8Ux7o")!) { (data, response, error) in
                    guard let data = data else { return }
                    do {
                        let address = try JSONDecoder().decode(PLaces.self, from: data)
                        if address.status == "ZERO_RESULTS" {
                            self.autoLocationSelected = true
                            self.autoLocationStatus(sender)
                        } else {
                            CLLocationManager.getLocation(forPlaceCalled: address.predictions[0].description!) { (location) in
                                if location == nil {
                                    self.autoLocationSelected = true
                                    self.autoLocationStatus(sender)
                                } else {
                                    self.lat = location!.coordinate.latitude
                                    self.lon = location!.coordinate.longitude
                                    
                                    DispatchQueue.main.async {
                                        self.cityLbl.stringValue = "City: " + self.currentCities[i]
                                        self.refreshWeatherContent(sender)
                                        
                                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
                                            activityIndicator.removeFromSuperview()
                                            self.dismissCityPicker()
                                        })
                                    }
                                }
                            }
                        }
                    } catch let error {
                        self.dialogOKCancel(question: "Error Parsing JSON:", text: error.localizedDescription)
                    }
                }.resume()
                break
            }
        }
    }
    
    @IBAction func refreshWeatherContent(_ sender: NSButton) {
        mainView.load(URLRequest(url: URL(string: "https://rawcdn.githack.com/ozanmirza1/Quick-Weather/38ecd617ec3f24f821dd45ee72e7160e1b8da9d0/CONTENT/index.html")!))
    }
    
    func dialogOKCancel(question: String, text: String) {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @IBAction func autoLocationStatus(_ sender: NSButton) {
        autoLocationSelected = !autoLocationSelected
        
        if autoLocationSelected == true {
            let bg = NSVisualEffectView(frame: self.view.bounds)
            bg.material = NSVisualEffectView.Material.appearanceBased
            self.view.addSubview(bg)
            let activityIndicator = NSProgressIndicator()
            activityIndicator.frame.size = NSSize(width: 35, height: 35)
            activityIndicator.frame.origin = NSPoint(x: (self.view.frame.size.width / 2) - 17.5, y: (self.view.frame.size.height / 2) - 17.5)
            activityIndicator.style = NSProgressIndicator.Style.spinning
            activityIndicator.startAnimation(self)
            bg.addSubview(activityIndicator)
            locationSelector.image = NSImage(named: NSImage.Name("location_selected_icon"))
            locationManager.startUpdatingLocation()
            lat = initLatLon.coordinate.latitude
            lon = initLatLon.coordinate.longitude
            self.refreshWeatherContent(sender)
            CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lon)) { (placemarks, error) in
                if error != nil {
                    self.dialogOKCancel(question: "Uh-Oh, can't find city! :(", text: "We can still display the weather for you, but not the city name.")
                } else {
                    guard let placeMark = placemarks?.first else { return }
                    
                    if let city = placeMark.subAdministrativeArea {
                        activityIndicator.stopAnimation(self)
                        bg.removeFromSuperview()
                        self.cityLbl.stringValue = "City: " + city
                    }
                }
            }
        } else {
            locationSelector.image = NSImage(named: NSImage.Name("location_unselected_icon"))
            locationManager.stopUpdatingLocation()
            
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 1
            cityPicker.animator().frame.origin.y = 87.5
            NSAnimationContext.endGrouping()
        }
    }
    
    @IBAction func closeCitypicker(_ sender: NSButton) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 1
        cityPicker.animator().frame.origin.y = 0 - cityPicker.frame.size.height
        NSAnimationContext.endGrouping()
        self.autoLocationStatus(sender)
    }
    
    func dismissCityPicker() {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 1
        cityPicker.animator().frame.origin.y = 0 - cityPicker.frame.size.height
        NSAnimationContext.endGrouping()
    }
    
    func autoCompleteCityNames(with contents: String, completion:@escaping (PLaces?)->()) {
        URLSession.shared.dataTask(with: URL(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=" + contents + "&types=(cities)&language=en&sensor=true&key=AIzaSyA8pukmW_of-7QT_Y1FH9MkqZOq4X8Ux7o")!) { (data, response, error) in
            guard let data = data else { return }
            do {
                return completion(try? JSONDecoder().decode(PLaces.self, from: data))
            }
        }.resume()
    }
}

extension PopUpViewController {
    // MARK: Storyboard instantiation
    static func freshController() -> PopUpViewController {
        //1.
        let storyboard = NSStoryboard(name: NSStoryboard.Name(stringLiteral: "Main"), bundle: nil)
        //2.
        let identifier = NSStoryboard.SceneIdentifier(stringLiteral: "PopUpViewController")
        //3.
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? PopUpViewController else {
            fatalError("Error: PopUp View Controller Not Found")
        }
        return viewcontroller
    }
}
