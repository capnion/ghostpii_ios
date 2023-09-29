//
//  ViewController.swift
//  PrivacyTest
//
//  Created by Jack Phillips on 4/12/23.
//

import UIKit
import Firebase
import WebKit

class MainViewController: UIViewController {
    
    @IBOutlet weak var signupButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard

        if let stringOne = defaults.string(
            forKey: "token"
        ) {
            print(stringOne) // Some String Value
        }
        if let stringTwo = defaults.string(
            forKey: "username"
        ) {
            print(stringTwo) // Another String Value
        }
        let hashInt = defaults.integer(forKey: "hash")
        print(hashInt) // Another String Value
        
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let defaults = UserDefaults.standard
        
        let hashInt = defaults.integer(forKey: "hash")

        if (hashInt != 0) {
            let secondVC = self.storyboard?.instantiateViewController(withIdentifier: "homeViewController") as! HomeViewController
            self.present(secondVC, animated:true, completion:nil)
        }
    }
    
    @IBAction func signupButtonTapped(_ sender: UIButton) {
        // Navigate to the sign up page
        performSegue(withIdentifier: "WelcomeToSignup", sender: self)
    }


}

class LoginViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add tap gesture recognizer to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }



    @IBAction func loginButtonTapped(_ sender: UIButton) {
        // Perform login logic here, e.g., validate credentials and navigate to home screen

        let username = usernameTextField.text ?? ""
        let password = passwordTextField.text ?? ""

        if username.isEmpty || password.isEmpty {
            showAlert(title: "Error", message: "Please enter both username and password.")
        } else {
            // Perform login logic, e.g., validate credentials with backend API
            // If login is successful, navigate to home screen
            // Otherwise, show error message

            performSegue(withIdentifier: "LoginSegue", sender: self)
        }
    }
    
    @IBAction func signupButtonTapped(_ sender: UIButton) {
        // Navigate to the sign up page
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "NewSignup") as! NewSignup
        
        self.navigationController?.pushViewController(vc, animated: true)
    }



    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}


// DEPRECATED
// This is the old signup page that works with a form
class SignupViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add any additional setup code here
    }
    
    // MARK: - IBActions
    
    @IBAction func signupButtonTapped(_ sender: UIButton) {
        // Handle signup logic here
        
        // Validate user input and perform signup
        guard let username = usernameTextField.text, !username.isEmpty,
              let email = emailTextField.text, !email.isEmpty else {
            // Show an alert for incomplete user input
            showAlert(withTitle: "Error", message: "Please fill in all the fields.")
            return
        }
        
        // Perform signup API call or other signup logic
        Task{
            await performSignup(username: username, email: email){ data,success in
                print("cool")
                
            }
        }
        
        
        // Show success message and navigate to the next screen
        showAlert(withTitle: "Success", message: "Signup successful!") { _ in
            self.navigateToNextScreen()
        }
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        // Here we navigate to the login page
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - Helper Methods
    
    func showAlert(withTitle title: String, message: String, completionHandler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: completionHandler)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func navigateToNextScreen() {
        // Example code: Navigate to the next screen
        let nextViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NextViewController")
        navigationController?.pushViewController(nextViewController, animated: true)
    }
}

class NewSignup: UIViewController {
    
    // MARK: - IBOutlets
    
    
    @IBOutlet weak var webViewer: WKWebView!
    
    @IBOutlet weak var saveTokenButton: UIButton!
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add any additional setup code here
        
        let myURL = URL(string:"https://ghostpii.com/user-signup/")
        let myRequest = URLRequest(url: myURL!)
        webViewer.load(myRequest)
        webViewer.pageZoom = 1.0
        webViewer.find("username")
    }
    
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        // Here we parse the html contained in the viewer
        webViewer.evaluateJavaScript("document.documentElement.outerHTML.toString()") {
            html ,_ in
            
            //print(html as! String)
            
            let newToken = HTMLParser().parseForIDToken(html: html as! String)
            let defaults = UserDefaults.standard
            
            //print(newToken)
            if (!newToken.contains("Error")){
                defaults.set(newToken, forKey: "token")
                Task{
                    await loginWithToken{ success, data in
                        if success{
                            let jsonData = data.data(using: .utf8)!
                            //print(jsonData)
                            let users = try! JSONDecoder().decode([userData].self, from: jsonData)
                            print("Parsed username")
                            let user = users.first!
                            defaults.set(user.username, forKey: "username")
                            print(user.username)
                            //let fullEncLength = user.username.count + encLength
                            let userID = idFromUrl(url: user.url)
                            Task{
                                let username = defaults.string(forKey: "username")!
                                print(username)
                                await getEncryptionKeys(encLength: username.count ){ success,data in
                                    if success {
                                        var encData = encryptWord(word: username, keys: data)
          
                                        var idList = [Int]()
                                        for key in data {
                                            idList.append(key.id)
                                        }
                                        let hashBounds = [idList.min()!,idList.max()!]
                                        print(hashBounds)
                                        Task{
                                            await getHash(str2Hash: encData, bounds: hashBounds){ success, data in
                                                if success{
                                                    let computedHash = computeHash(hashStr: encData, hashInfo: data)
                                                    print("GOT HASH DATA")
                                                    print(computedHash)
                                                    defaults.set(computedHash, forKey: "hash")
                                                    
                                                    
                                                }
                                                else{
                                                    print("waiting")
                                                }
                                                
                                            }
                                        }
                                        
                                    }
                                    else {
                                        print("waiting on encryption keys")
                                    }
                                }
                            }
                        }
                    }
                    
                    
                }
                
                
            }
            
            let secondVC = self.storyboard?.instantiateViewController(withIdentifier: "homeViewController") as! HomeViewController
            self.present(secondVC, animated:true, completion:nil)
          
            
            
        }

            //let result = value as? String
            //Main logic

        
    }
    
}

class HomeViewController: UIViewController {
    
    @IBOutlet weak var calendarButton: UIButton!

    @IBOutlet weak var analyticsButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }
    
    @IBAction func calendarButtonTapped(_ sender: UIButton) {
        // Here we navigate to the login page
        
        let secondVC = storyboard?.instantiateViewController(withIdentifier: "calendarViewController") as! CalendarViewController
        self.present(secondVC, animated:true, completion:nil)
    }
    
    @IBAction func analyticsButtonTapped(_ sender: UIButton) {
        // Navigate to the sign up page
        performSegue(withIdentifier: "toAnalytics", sender: self)
    }


}

class AnalyticsViewController: UIViewController{
    
    
    @IBOutlet weak var avgLabel: UILabel!
    @IBOutlet weak var medianLabel: UILabel!
    @IBOutlet weak var stdevLabel: UILabel!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    
    var meetingList = [MeetingInfo]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getMeetingsFromCloud(){ success, data in
            if success{
                var meetingHashes = [Int]()
                for meeting in data {
                    meetingHashes.append(meeting.dateHash)
                }
                
                let counts = meetingHashes.reduce(into: [:]) { $0[$1, default: 0] += 1 }
                print(counts)
                
                //Calculate average
                let avg = Double(meetingHashes.count) / Double(counts.count)
                self.avgLabel.text = String(avg)
                
                //Calculate max/min
                self.maxLabel.text = String(counts.values.max()!)
                self.minLabel.text = String(counts.values.min()!)

                //Calculate median
                let sortedCounts = Array(counts.values.sorted())
                if counts.count == 1 {
                    self.medianLabel.text = String(counts.values.max()!)
                }
                else {
                    
                    var median = 0.0
                    let midpoint = sortedCounts.count/2
                    if counts.count % 2 == 1 {
                        median = Double(sortedCounts[midpoint])
                    }
                    else {
                        median = Double(sortedCounts[midpoint] + sortedCounts[midpoint-1]) / 2.0
                    }
                    self.medianLabel.text = String(median)
                }
                
                
                
                //Calculate std deviation
                if sortedCounts.count > 1 {
                    let doubleCounts = sortedCounts.map { Double($0) }
                    let v = doubleCounts.reduce(0, { $0 + ($1-avg)*($1-avg) })
                    let stdev = sqrt(v/Double(doubleCounts.count-1))
                    self.stdevLabel.text = String(stdev)
                }
                
                
                
                

                
            }
            else{
                print("Waiting on data from cloud")
            }
        }
        
    }
    
    func getMeetingsFromCloud(completion: @escaping (_ success: Bool, _ data: [MeetingInfo]) -> Void) {
        
        // get a reference to the Firebase db
        let db = Firestore.firestore()
        
        let defaults = UserDefaults.standard
        let hashInt = defaults.integer(forKey: "hash")
        
        // read the documents
        db.collection(String(hashInt)).getDocuments{ (snapshot, error) in
            
            
            
            if error == nil {
                
                //create DateInfo objects
                if let snapshot = snapshot {
                    
                    DispatchQueue.main.async {
                        
                    
                        let meetingList = snapshot.documents.map({ doc in
                            
                            return MeetingInfo(docID: doc.documentID, date: doc["date"] as? String ?? "", dateHash: doc["dateHash"] as! Int , dateBounds: doc["dateBounds"] as? Array<Int> ?? [Int](),  username: doc["username"] as? String ?? "", usernameBounds: doc["usernameBounds"] as? Array<Int> ?? [Int](), description: doc["description"] as? String ?? "", descBounds: doc["descBounds"] as? Array<Int> ?? [Int]())
                            
                        })
                        
                        self.meetingList = meetingList
                        print(meetingList)
                        completion(true,meetingList)
                    }
                }
            }
            else {
                //handle the error
                print("No docs in database")
            }
            
        }
        
    }
}


class CalendarViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    

    // MARK: - Properties
    var dateList = [DateInfo]()

    private var calendar = Calendar.current
    private var currentDate = Date()
    private var monthStartDate: Date {
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        return calendar.date(from: components)!
    }
    private var daysInMonth: Int {
        return calendar.range(of: .day, in: .month, for: monthStartDate)!.count
    }
    private var firstWeekdayOfMonth: Int {
        let components = calendar.dateComponents([.weekday], from: monthStartDate)
        return components.weekday!
    }
    var selectedDays: [Int: Int] = [:]
    
    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self

        monthLabel.text = "\(calendar.monthSymbols[calendar.component(.month, from: currentDate) - 1]) \(calendar.component(.year, from: currentDate))"
        
        
        /*
        getDataFromCloud(){ success, data in
            if success{
                var fullBounds = [Int]()
                let myDoc = data[0]
                
                fullBounds.append(myDoc.usernameBounds[0] as! Int)
                fullBounds.append(myDoc.flowRateIndex)
                var boundList = [Int]()
                for i in fullBounds[0]...fullBounds[1]{
                    boundList.append(i)
                }
                
                Task{
                    await getDecryptKeys(keyList: boundList) { success, data in
                        if success{
                            let decDateInfo = decryptDate(dates: myDoc, keys: data)
                            print(decDateInfo)
                        }
                        else{
                            print("waitin")
                        }
                        
                    }
                }
                
                let hashBounds = Array(boundList[0..<(myDoc.username.count/3)])
                
                
                
                Task{
                    await getHash(str2Hash: myDoc.username, bounds: hashBounds){ success, data in
                        if success{
                            let computedHash = computeHash(hashStr: myDoc.username, hashInfo: data)
                            print("GOT HASH DATA")
                            print(computedHash)
                        }
                        else{
                            print("waiting")
                        }
                        
                    } 
                }
            }
            else {
                print("Waiting on cloud data")
            }
            
        }
        */
        
    }

    // MARK: - Actions

    @IBAction func previousButtonTapped(_ sender: UIButton) {
        currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        //print(currentDate.formatted(date: .numeric, time: .omitted))
        updateMonthLabel()
        collectionView.reloadData()

    }

    @IBAction func nextButtonTapped(_ sender: UIButton) {
        currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        //print(currentDate.formatted(date: .numeric, time: .omitted))
        updateMonthLabel()
        collectionView.reloadData()
        
    }

    // MARK: - Helper Methods

    private func updateMonthLabel() {
        monthLabel.text = "\(calendar.monthSymbols[calendar.component(.month, from: currentDate) - 1]) \(calendar.component(.year, from: currentDate))"
    }
    
    
    func getDataFromCloud(completion: @escaping (_ success: Bool, _ data: [DateInfo]) -> Void) {
        
        // get a reference to the Firebase db
        let db = Firestore.firestore()
        
        let defaults = UserDefaults.standard
        let hashInt = defaults.integer(forKey: "hash")
        
        // read the documents
        db.collection(String(hashInt)).getDocuments{ (snapshot, error) in
            
            
            
            if error == nil {
                
                //create DateInfo objects
                if let snapshot = snapshot {
                    
                    DispatchQueue.main.async {
                        
                    
                        let dateList = snapshot.documents.map({ doc in
                            
                            return DateInfo(docID: doc.documentID, date: doc["date"] as? String ?? "", dateBounds: doc["dateBounds"] as? Array<Int> ?? [Int](), flowRate: doc["flowRate"] as! Int , flowRateIndex: doc["flowRateIndex"] as! Int, username: doc["username"] as? String ?? "", usernameBounds: doc["usernameBounds"] as? Array<Int> ?? [Int]())
                            
                        })
                        
                        self.dateList = dateList
                        print(dateList)
                        completion(true,dateList)
                    }
                }
            }
            else {
                //handle the error
                print("No docs in database")
            }
            
        }
        
    }
    
    
}

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}

// MARK: - Collection View Data Source

extension CalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return daysInMonth + firstWeekdayOfMonth - 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! DayCell
        
        if indexPath.item < firstWeekdayOfMonth - 1 {
            cell.dayButton.setTitle("", for: .normal)
        } else {
            let day = indexPath.item - firstWeekdayOfMonth + 2
            cell.dayButton.setTitle("\(day)", for: .normal)
            cell.didSelectDay = { selectedDay in
                // Update the day for this cell
                self.selectedDays[day] = selectedDay
                
            }
            cell.fullDate = calendar.date(byAdding: .day, value: -1*currentDate.get(.day)+day, to: currentDate)
        }
        
        return cell
    }
}

// MARK: - Collection View Delegate Flow Layout

extension CalendarViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 2) / 7
        let height = width
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - Day Cell

class DayCell: UICollectionViewCell {
    
    // MARK: - Outlets
    
    @IBOutlet weak var dayButton: UIButton!
    
    // MARK: - Properties
    
    var day: Int?
    var didSelectDay: ((Int?) -> Void)?
    var fullDate: Date?
    
    let gradientColors: [UIColor] = [
        UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), // white
        UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0), // light pink
        UIColor(red: 1.0, green: 0.6, blue: 0.6, alpha: 1.0), // pink
        UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0), // dark pink
        UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0), // light red
        UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), // red
    ]
    
    let flowRates: [String] = [
        "None",
        "Very Light",
        "Light",
        "Medium",
        "Heavy",
        "Very Heavy",
    ]
    
    // MARK: - Actions
    
    
    @IBAction func dayButtonTapped(_ sender: UIButton) {
        print("button tapped")
        let alertController = UIAlertController(title: "Enter a new meeting", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.text = "Describe your meeting"
        }
        


        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alertController] (_) in
            let textField = alertController?.textFields![0] // Force unwrapping because we know it exists.
            let textData = textField!.text!
            let dateStr = self.fullDate!.formatted(date: .numeric, time: .omitted)
            let defaults = UserDefaults.standard
            let username = defaults.string(forKey: "username")!
            
            Task{
                await getEncryptionKeys(encLength: dateStr.count + username.count + textField!.text!.count){ success, data in
                    if success {
                        var encData = encryptMeeting(dateStr: dateStr, username: username, description: textData, keys: data)
                        Task{
                            await getHash(str2Hash: encData.date,bounds: encData.dateBounds){ success, data in
                                if success {
                                    let computedHash = computeHash(hashStr: encData.date, hashInfo: data)
                                    print("GOT HASH DATA")
                                    print(computedHash)
                                    encData.dateHash = computedHash
                                    
                                    addMeetingToDatabase(meetingInfo: encData)
                                }
                                else {
                                    print("waiting on hash data")
                                }
                                
                            }
                        }
                        //addToDatabase(dateInfo: encData)
                        
                    }
                    else {
                        print("waiting on encryption keys")
                    }
                }
                
            }
            
        }))
        /*
        for i in 0...5 {
            alertController.addAction(UIAlertAction(title: self.flowRates[i], style: .default, handler: { _ in
                //self.day = i
                //self.dayButton.setTitle("\(i)", for: .normal)
                //self.dayButton.backgroundColor = self.gradientColors[i]
                //self.didSelectDay?(i)
                let dateStr = self.fullDate!.formatted(date: .numeric, time: .omitted)
                let defaults = UserDefaults.standard
                let username = defaults.string(forKey: "username")!
                
                Task{
                    await getEncryptionKeys(encLength: dateStr.count + username.count + 1 ){ success,data in
                        if success {
                            var encData = encryptDate(username: username, flowRate: i, dateStr: dateStr, keys: data)
                            addToDatabase(dateInfo: encData)
                            
                        }
                        else {
                            print("waiting on encryption keys")
                        }
                    }
                    
                }
            }))
        }*/
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if var viewController = self.window?.rootViewController {
            while let presentedViewController = viewController.presentedViewController {
                    viewController = presentedViewController
                }
            viewController.present(alertController, animated: true)
        }
    }
}


