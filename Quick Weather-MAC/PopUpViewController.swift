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
import Alamofire

class PopUpViewController: NSViewController, WKUIDelegate, WKNavigationDelegate, CLLocationManagerDelegate, NSTextFieldDelegate {
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    var lat = Double()
    var lon = Double()
    var locationSent = false
    var autoLocationSelected = true
    var setCity = false
    var initLatLon = CLLocation()
    var currentCities : [String] = []
    
    @IBOutlet weak var mainView: WKWebView!
    @IBOutlet weak var exitBtn: NSButton!
    @IBOutlet weak var main_icon: NSImageView!
    @IBOutlet weak var refresBtn: NSButton!
    @IBOutlet weak var locationSelector: NSButton!
    @IBOutlet weak var cityLbl: NSTextField!
    @IBOutlet weak var cityPicker: NSVisualEffectView!
    @IBOutlet weak var citySetter: NSTextField!
    @IBOutlet weak var autoViews: NSView!
    @IBOutlet weak var switcherBackground: NSView!
    @IBOutlet weak var switcherHighlight: NSView!
    @IBOutlet var highlightX: NSLayoutConstraint!
    @IBOutlet var switcherX: NSLayoutConstraint!
    @IBOutlet var powerX: NSLayoutConstraint!
    @IBOutlet var labelx: NSLayoutConstraint!
    @IBOutlet weak var helpLbl: NSStackView!
    @IBOutlet weak var locationGetter: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Weather Content: https://rawcdn.githack.com/Aries-Sciences-LLC/Quick-Weather/14740f1daf51a4296044d90b57355aa8a36e4ba8/BASE_FILES/index.html
        // City Names: https://raw.githubusercontent.com/lutangar/cities.json/master/cities.json
        
        if UserDefaults.standard.string(forKey: "units") == nil {
            UserDefaults.standard.setValue("F", forKey: "units")
        }
        
        if UserDefaults.standard.string(forKey: "units") == "F" {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0.3
            highlightX.animator().constant = 60
            NSAnimationContext.endGrouping()
        }
        
        self.citySetter.delegate = self
        self.citySetter.focusRingType = NSFocusRingType.none
        self.locationGetter.startAnimation(self)
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        cityPicker.wantsLayer = true
        cityPicker.layer?.cornerRadius = 5
        cityPicker.layer?.masksToBounds = true
        cityPicker.layer?.borderColor = NSColor.white.cgColor
        cityPicker.frame.origin.y = 0 - cityPicker.frame.size.height
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            self.locationManager.requestLocation() // Front use
            self.locationManager.startUpdatingLocation()
        }
        
        self.view.wantsLayer = true
        switcherHighlight.wantsLayer = true
        switcherBackground.wantsLayer = true
        switcherHighlight.layer?.backgroundColor = NSColor.darkGray.withAlphaComponent(0.6).cgColor
        switcherBackground.layer?.backgroundColor = NSColor.lightGray.withAlphaComponent(0.6).cgColor
        switcherHighlight.layer?.cornerRadius = 5
        switcherBackground.layer?.cornerRadius = 5
        
        switcherX.constant = -120
        powerX.constant = -100
        labelx.constant = -250
    }
    
    @IBAction func usingCustomLocation(_ sender: NSButton!) {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
        NSApplication.shared.terminate(self)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.3
        self.helpLbl.animator().alphaValue = 1
        NSAnimationContext.endGrouping()
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
            self.locationGetter.animator().alphaValue = 0
            self.helpLbl.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                self.mainView.uiDelegate = self
                self.mainView.navigationDelegate = self
                self.mainView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
                self.mainView.load(URLRequest(url: URL(string: "https://rawcdn.githack.com/Aries-Sciences-LLC/Quick-Weather/14740f1daf51a4296044d90b57355aa8a36e4ba8/BASE_FILES/index.html")!))
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        locationSent = true
        mainView.evaluateJavaScript("getWeatherData(\(lat), \(lon), \"\(UserDefaults.standard.string(forKey: "units")!)\");", completionHandler: nil)
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.3
        switcherBackground.animator().alphaValue = 1
        NSAnimationContext.endGrouping()
        locationSelector.isEnabled = true
    }
    
    @IBAction func quitApplication(_ sender: NSButton) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func userTypedCity(_ sender: Any!) {
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
                        subLbl.font = NSFont.systemFont(ofSize: 15, weight: .light)
                        subLbl.title = parsedData!.predictions[i].description!
                        subLbl.isBordered = false
                        subLbl.action = #selector(self.setCustomLocation(_:))
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
                var request = URLRequest(url: URL(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=" + currentCities[i].forSorting + "&types=address&language=en&sensor=true&key=AIzaSyA5n9gxzURnB5TSwHWYTlfDRw45XbNanQE")!)
                request.httpMethod = "GET"
                AF.request(request).response { response in
                    guard let data = response.data else { return }
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
                                        self.cityLbl.stringValue = self.currentCities[i]
                                        self.refreshWeatherContent(sender)
                                        self.autoLocationSelected = false
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
                }
                break
            }
        }
    }
    
    @IBAction func refreshWeatherContent(_ sender: Any) {
        mainView.load(URLRequest(url: URL(string: "https://rawcdn.githack.com/Aries-Sciences-LLC/Quick-Weather/14740f1daf51a4296044d90b57355aa8a36e4ba8/BASE_FILES/index.html")!))
    }
    @IBAction func changeToCelcius(_ sender: Any) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.3
        highlightX.animator().constant = 8
        NSAnimationContext.endGrouping()
        UserDefaults.standard.setValue("C", forKey: "units")
        refreshWeatherContent(sender)
        dismissCityPicker()
    }
    @IBAction func changeToFarenheit(_ sender: Any) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.3
        highlightX.animator().constant = 60
        NSAnimationContext.endGrouping()
        UserDefaults.standard.setValue("F", forKey: "units")
        refreshWeatherContent(sender)
        dismissCityPicker()
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
        if !autoLocationSelected {
            autoLocationSelected = true
            let bg = NSVisualEffectView(frame: self.view.bounds)
            bg.material = NSVisualEffectView.Material.appearanceBased
            self.view.addSubview(bg)
            let activityIndicator = NSProgressIndicator()
            activityIndicator.frame.size = NSSize(width: 35, height: 35)
            activityIndicator.frame.origin = NSPoint(x: (self.view.frame.size.width / 2) - 17.5, y: (self.view.frame.size.height / 2) - 17.5)
            activityIndicator.style = NSProgressIndicator.Style.spinning
            activityIndicator.startAnimation(self)
            bg.addSubview(activityIndicator)
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
                        self.cityLbl.stringValue = city
                    }
                }
            }
        } else {
            locationManager.stopUpdatingLocation()
            
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0.3
            cityPicker.animator().frame.origin.y = 87.5
            switcherX.animator().constant = 20
            powerX.animator().constant = 20
            labelx.animator().constant = 20
            NSAnimationContext.endGrouping()
        }
    }
    
    @IBAction func closeCitypicker(_ sender: NSButton) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.3
        cityPicker.animator().frame.origin.y = 0 - cityPicker.frame.size.height
        switcherX.animator().constant = -120
        powerX.animator().constant = -100
        labelx.animator().constant = -250
        NSAnimationContext.endGrouping()
    }
    
    func dismissCityPicker() {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = 0.3
        cityPicker.animator().frame.origin.y = 0 - cityPicker.frame.size.height
        switcherX.animator().constant = -120
        powerX.animator().constant = -100
        labelx.animator().constant = -250
        NSAnimationContext.endGrouping()
    }
    
    func autoCompleteCityNames(with contents: String, completion: @escaping (PLaces?)->()) {
        var request = URLRequest(url: URL(string: "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=" + contents + "&types=(cities)&language=en&sensor=true&key=AIzaSyA5n9gxzURnB5TSwHWYTlfDRw45XbNanQE")!)
        request.httpMethod = "GET"
        AF.request(request).response { response in
            guard let data = response.data else { return }
            do {
                return completion(try? JSONDecoder().decode(PLaces.self, from: data))
            }
        }
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
