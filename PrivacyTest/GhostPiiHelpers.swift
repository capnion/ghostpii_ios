//
//  GhostPiiHelpers.swift
//  PrivacyTest
//
//  Created by Jack Phillips on 5/16/23.
//

import Foundation
import SwiftSoup
import Firebase


//MARK: - Parsing helpers

final class HTMLParser {
    func parseForMiddlewareToken (html: String) -> String{
        do {
            let document : Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                print("Document has no .body() element")
                return "no .body element"
            }
            
            let middleware = try body.getElementsByAttributeValue("name", "csrfmiddlewaretoken")
            //print("MIDDLEWARE TOKEN")
            //`print(try middleware.val())
            
            let middlewareToken = try middleware.val()
            return middlewareToken
            
        }
        catch {
            print("Error Parsing: " + String(describing: error))
            return "Error Parsing: " + String(describing: error)
        }
    }
    
    func parseForIDToken (html: String) -> String{
        var newToken = ""
        
        do {
            let document : Document = try SwiftSoup.parse(html)
            guard let body = document.body() else {
                print("Document has no .body() element")
                return "Error: no .body element"
            }
            let token = try body.getElementsByClass("token")[0]
            print(try token.html())
            
            //print("MIDDLEWARE TOKEN")
            //`print(try middleware.val())
            
            let newToken = try token.html()
            print(newToken)
            return newToken
            
        }
        catch {
            print("Error Parsing: " + String(describing: error))
            return "Error Parsing: " + String(describing: error)
        }

    }
    
}

func idFromUrl (url: String) -> Int {
    let keyAndValue = /\d+/
    if let match = url.firstMatch(of: keyAndValue) {
        //print(match.output)
        return Int(match.output) ?? 0
    }
    else {
        print("Couldn't parse")
        return 0
    }
}



// MARK: - API calls

func loginWithToken(_ completion: @escaping (_ success: Bool, _ data: String) -> Void) async{
    
    
    let urlLogin = URL(string: "https://ghostpii.com/api/api-auth/login/")!
    let defaults = UserDefaults.standard
    let token = defaults.string(forKey: "token")!
    let headers = [
        "Authorization": token
    ]
    
    
    do{
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = headers
        config.httpShouldSetCookies = true
        let session = URLSession.init(configuration: config)
        
        let (data, _) = try await session.data(from: urlLogin)
        let str = String(data: data, encoding: .utf8)!
        //print(str)
        //print("RESPONSE")
        //print(response)
        //print("Value")
        
        let middlewareToken = HTMLParser().parseForMiddlewareToken(html: str)
        
        let parameters: [String: String] = ["username":"jackphillips2", "password":"uniquepassword", "next":"/", "csrfmiddlewaretoken" : middlewareToken]
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        
        var postRequest = URLRequest(url: urlLogin)
        postRequest.httpMethod = "POST"
        postRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        postRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        postRequest.httpBody = jsonData
        
        let defaults = UserDefaults.standard
        let token = defaults.string(forKey: "token")!

        postRequest.setValue(token, forHTTPHeaderField: "Authorization")
        
        //print("\(postRequest.httpMethod!) \(postRequest.url!)")
        //print(postRequest.allHTTPHeaderFields!)
        //print(String(data: postRequest.httpBody ?? Data(), encoding: .utf8)!)
        
        //let cookieStorage = session.configuration.httpCookieStorage
        //let cookies = cookieStorage?.cookies!
        //print("Cookies.count: \(cookies?.count ?? 0)")
        
        let dataTask = session.dataTask(with: postRequest) { data2, response2, error in
            guard let data2 = data2, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    return
                }
            
            //print("Getting response")
            //print(response2!)
            //print("data")
            //let str2 = String(data: data2, encoding: .utf8)!
            //print(str2)
                        
        }
        
        
        dataTask.resume()
        
        var urlUser = URL(string: "https://ghostpii.com/api/users/")!
        var userRequest = URLRequest(url: urlUser)
        userRequest.httpMethod = "GET"
        
        
        
        let dataTask2 = session.dataTask(with: userRequest) { data3, response3, error in
            guard let data3 = data3, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    return
                }
            
            //print("Getting response")
            //print(response3!)
            //print("data")
            let str3 = String(data: data3, encoding: .utf8)!
            //print("****************")
            //print(str3)
            completion(true,str3)
            
        }.resume()
        
    }
    catch {
        completion(false,"error")
        return
    }
    
    
    completion(false,"error")
    return
}

func getEncryptionKeys(encLength : Int, completion: @escaping (_ success: Bool, _ data: [encryptKey]) -> Void) async {
    
    let defaults = UserDefaults.standard
    let token = defaults.string(forKey: "token")!
    let headers = [
        "Authorization": token
    ]
    
    
    await loginWithToken{ success, data in
        if success{
            let jsonData = data.data(using: .utf8)!
            //print(jsonData)
            let users = try! JSONDecoder().decode([userData].self, from: jsonData)
            print("Parsed username")
            let user = users.first!
            //print(user.username)
            //let fullEncLength = user.username.count + encLength
            let fullEncLength = encLength
            let userID = idFromUrl(url: user.url)
            //print(userID)
            
            //Now that we have the User ID we can reserve encryption keys
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = headers
            let session = URLSession.init(configuration: config)
            
            let urlState = URL(string: "https://ghostpii.com/api/state/?length=\(fullEncLength)&range=5000")!
            var stateRequest = URLRequest(url: urlState)
            stateRequest.httpMethod = "GET"
            
            let dataTask = session.dataTask(with: stateRequest) { data, response, error in
                guard let data = data, error == nil else {
                        print(error?.localizedDescription ?? "No data")
                        return
                    }
                
                //print("Getting response")
                //print(response!)
                //print("data")
                let str = String(data: data, encoding: .utf8)!
                //print(str)
                let tempBounds = try! JSONDecoder().decode([stateInfo].self, from: data)
                let bounds = tempBounds.first!
                //print(bounds)
                let urlEncrypt = URL(string: "https://ghostpii.com/api/staticencrypt/?lower=\(bounds.minId)&upper=\(bounds.maxId)" )!
                
                var encryptRequest = URLRequest(url: urlEncrypt)
                encryptRequest.httpMethod = "GET"
                
                let encryptTask = session.dataTask(with: encryptRequest){ encData, encResponse, encError in
                    
                    guard let encData = encData, encError == nil else {
                            print(error?.localizedDescription ?? "No data")
                            return
                        }
                    
                    let encStr = String(data: encData, encoding: .utf8)!
                    
                    //print("Encrypt data")
                    //print(encStr)
                    
                    let encKeys = try! JSONDecoder().decode([encryptKey].self, from: encData)
                    //print(encKeys)
                    completion(true,encKeys)
                    
                }.resume()
                
                            
            }.resume()
            
        }
        else{
            print("Waiting on login info...")
        }
        
    }
    completion(false,[])
}


func getDecryptKeys(keyList: [Int], completion: @escaping (_ success: Bool, _ data: [encryptKey]) -> Void) async{
    let defaults = UserDefaults.standard
    let token = defaults.string(forKey: "token")!
    let headers = [
        "Authorization": token
    ]
    
    
    await loginWithToken{ success, data in
        if success{
            let jsonData = data.data(using: .utf8)!
            //print(jsonData)
            let users = try! JSONDecoder().decode([userData].self, from: jsonData)
            //print("Parsed username")
            let user = users.first!
            //print(user.username)
            
            let userID = idFromUrl(url: user.url)
            //print(userID)
            
            //Now that we have the User ID we can reserve encryption keys
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = headers
            let session = URLSession.init(configuration: config)
            
            let urlBlob = URL(string: "https://ghostpii.com/api/blob/")!
            var blobRequest = URLRequest(url: urlBlob)
            blobRequest.httpMethod = "POST"
            blobRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            blobRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let stringArray = keyList.map { String($0) }
            let keyString = "[" + stringArray.joined(separator: ",") + "]"
            //print(keyString)

            let myTimestamp = Int(String(Date().timeIntervalSince1970).replacingOccurrences(of: ".", with: ""))
    
            
            let blobData: [String: Any] = ["assigned_user": userID, "keyJSON":keyString, "userhash": myTimestamp!]
            
            
            blobRequest.httpBody = try? JSONSerialization.data(withJSONObject:blobData)
            //print(String(data:try! JSONSerialization.data(withJSONObject:blobData),encoding: .utf8)!)
            
            
            let dataTask = session.dataTask(with: blobRequest) { data, response, error in
                guard let data = data, error == nil else {
                        print(error?.localizedDescription ?? "No data")
                        return
                }
                
                //let str = String(data: data, encoding: .utf8)!
                //print(str)
                let urlDecrypt = URL(string: "https://ghostpii.com/api/decrypt/?blobData=" + String(myTimestamp!))!
                var decryptRequest = URLRequest(url: urlDecrypt)
                decryptRequest.httpMethod = "GET"
                
                let decryptTask = session.dataTask(with: decryptRequest){ data,response,error in
                    guard let data = data, error == nil else {
                        print(error?.localizedDescription ?? "No data")
                        return
                    }
                    
                    let encKeys = try! JSONDecoder().decode([encryptKey].self, from: data)
                    //print(encKeys)
                    completion(true,encKeys)
                    
                }.resume()
               
                
                            
            }.resume()
        }
        else{
            print("Waiting on decrypt info...")
        }
        
    }
    completion(false,[])
}

func addToDatabase(dateInfo: DateInfo){
    let db = Firestore.firestore()
    
    db.collection("Days").addDocument(data: ["date": dateInfo.date,
                                             "dateBounds": dateInfo.dateBounds,
                                             "flowRate":dateInfo.flowRate,
                                             "flowRateIndex":dateInfo.flowRateIndex,
                                             "username": dateInfo.username,
                                             "usernameBounds": dateInfo.usernameBounds]){
        error in
        if error == nil{
            print("Successful upload")
        }
        else{
            print("Failed upload")
        }
    }
}

func addMeetingToDatabase(meetingInfo: MeetingInfo){
    let db = Firestore.firestore()
    let defaults = UserDefaults.standard
    let hashInt = defaults.integer(forKey: "hash")
    
    
    
    db.collection(String(hashInt)).addDocument(data: ["date": meetingInfo.date,
                                                      "dateHash":meetingInfo.dateHash,
                                                      "dateBounds":meetingInfo.dateBounds,
                                                      "description":meetingInfo.description,
                                                      "descBounds":meetingInfo.descBounds,
                                                      "username":meetingInfo.username,
                                                      "usernameBounds":meetingInfo.usernameBounds
                                                     ]){
        error in
        if error == nil{
            print("Successful upload")
        }
        else{
            print("Failed upload")
        }
    }
}

func encryptDate(username: String, flowRate: Int, dateStr: String, keys: [encryptKey]) -> DateInfo {
    
    let encodedUsername = username.asciiValues
    let encodedDateStr = dateStr.asciiValues
    //print(encodedUsername.count)
    //print(encodedDateStr.count)
    //print(keys.count)
    
    var encryptedUsernameList = [Int]()
    for i in 0..<encodedUsername.count{
        encryptedUsernameList.append(keys[i].atom_key + Int(encodedUsername[i]))
    }
    let usernameBounds = [keys[0].id,keys[encodedUsername.count-1].id]
    let cipherUsername = createCiphertext(encryptedVals: encryptedUsernameList)
    
    
    var encryptedDateStrList = [Int]()
    for i in 0..<encodedDateStr.count{
        encryptedDateStrList.append(keys[i+encodedUsername.count].atom_key + Int(encodedDateStr[i]))
    }
    let dateStrBounds = [keys[encodedUsername.count].id,keys[encodedUsername.count + encodedDateStr.count-1].id]
    let cipherDateStr = createCiphertext(encryptedVals: encryptedDateStrList)
    
    let encryptedFlowRate = flowRate + keys.last!.atom_key
    let flowRateIndex = keys.last!.id
    
    
    
    
    
    
    
    return DateInfo(docID: "Test", date: cipherDateStr, dateBounds: dateStrBounds, flowRate: encryptedFlowRate, flowRateIndex: flowRateIndex, username: cipherUsername, usernameBounds: usernameBounds)
}

func encryptWord(word: String, keys: [encryptKey]) -> String{
    let encodedWord = word.asciiValues
    var encryptedWordList = [Int]()
    for i in 0..<encodedWord.count{
        encryptedWordList.append(keys[i].atom_key + Int(encodedWord[i]))
    }
    let wordBounds = [keys[0].id,keys[encodedWord.count-1].id]
    let cipherUsername = createCiphertext(encryptedVals: encryptedWordList)
    
    return cipherUsername
    
}

func encryptMeeting(dateStr:String, username:String, description:String, keys:[encryptKey]) -> MeetingInfo{
    
    let encodedUsername = username.asciiValues
    let encodedDateStr = dateStr.asciiValues
    let encodedDescription = description.asciiValues
    //print(encodedUsername.count)
    //print(encodedDateStr.count)
    //print(keys.count)
    
    var encryptedUsernameList = [Int]()
    for i in 0..<encodedUsername.count{
        encryptedUsernameList.append(keys[i].atom_key + Int(encodedUsername[i]))
    }
    let usernameBounds = [keys[0].id,keys[encodedUsername.count-1].id]
    let cipherUsername = createCiphertext(encryptedVals: encryptedUsernameList)
    
    
    var encryptedDateStrList = [Int]()
    for i in 0..<encodedDateStr.count{
        encryptedDateStrList.append(keys[i+encodedUsername.count].atom_key + Int(encodedDateStr[i]))
    }
    let dateStrBounds = [keys[encodedUsername.count].id,keys[encodedUsername.count + encodedDateStr.count-1].id]
    let cipherDateStr = createCiphertext(encryptedVals: encryptedDateStrList)
    
    var encryptedDescriptionList = [Int]()
    for i in 0..<encodedDescription.count{
        encryptedDescriptionList.append(keys[i+encodedUsername.count+encodedDateStr.count].atom_key + Int(encodedDescription[i]))
    }
    let descriptionBounds = [keys[encodedUsername.count+encodedDateStr.count].id,keys[encodedUsername.count + encodedDateStr.count+encodedDescription.count-1].id]
    let cipherDescription = createCiphertext(encryptedVals: encryptedDescriptionList)
    
    
    return MeetingInfo(docID: "random", date: cipherDateStr, dateHash: 0, dateBounds: dateStrBounds, username: cipherUsername, usernameBounds: usernameBounds, description: cipherDescription, descBounds: descriptionBounds)
}

func decryptDate(dates: DateInfo, keys: [encryptKey]) -> DateInfo {
    let encodedUsername = decodeCiphertext(cipherString: dates.username)
    let encodedDateStr = decodeCiphertext(cipherString: dates.date)
    
    var decryptedUsernameList = [Int]()
    for i in 0..<encodedUsername.count{
        decryptedUsernameList.append(Int(encodedUsername[i]) - keys[i].atom_key)
    }
    
    var decryptedDateStrList = [Int]()
    for i in 0..<encodedDateStr.count{
        decryptedDateStrList.append( Int(encodedDateStr[i]) - keys[i+encodedUsername.count].atom_key)
    }
    
    let decryptedUsername = ascii2String(asciiVals: decryptedUsernameList)
    let decryptedDateStr = ascii2String(asciiVals: decryptedDateStrList)
    let decryptedFlowRate = dates.flowRate - keys.last!.atom_key
    
    return DateInfo(docID: dates.docID, date: decryptedDateStr, dateBounds: dates.dateBounds, flowRate: decryptedFlowRate, flowRateIndex: dates.flowRateIndex, username: decryptedUsername, usernameBounds: dates.usernameBounds)
    
}

func getHash(str2Hash: String, bounds: [Int], completion: @escaping (_ success: Bool, _ data: hashInfo) -> Void) async{
    
    let encodedStr = decodeCiphertext(cipherString: str2Hash)
    
    let defaults = UserDefaults.standard
    let token = defaults.string(forKey: "token")!
    let headers = [
        "Authorization": token
    ]
    
    
    await loginWithToken{ success, data in
        if success{
            let jsonData = data.data(using: .utf8)!
            //print(jsonData)
            let users = try! JSONDecoder().decode([userData].self, from: jsonData)
            print("Parsed username")
            let user = users.first!
            print(user.username)
            
            let userID = idFromUrl(url: user.url)
            //print(userID)
            
            //Now that we have the User ID we can reserve encryption keys
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = headers
            let session = URLSession.init(configuration: config)
            
            let urlBlob = URL(string: "https://ghostpii.com/api/blob/")!
            var blobRequest = URLRequest(url: urlBlob)
            blobRequest.httpMethod = "POST"
            blobRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            blobRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let stringArray = bounds.map { String($0) }
            let keyString = "[" + stringArray.joined(separator: ",") + "]"
            //print(keyString)
            
            let myTimestamp = Int(String(Date().timeIntervalSince1970).replacingOccurrences(of: ".", with: ""))
            
            
            let blobData: [String: Any] = ["assigned_user": userID, "keyJSON":keyString, "userhash": myTimestamp!]
            
            
            blobRequest.httpBody = try? JSONSerialization.data(withJSONObject:blobData)
            //print(String(data:try! JSONSerialization.data(withJSONObject:blobData),encoding: .utf8)!)
            
            let dataTask = session.dataTask(with: blobRequest) { data, response, error in
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    return
                }
                print("BLOBINFO")
                let str = String(data: data, encoding: .utf8)!
                print(str)
                
                var urlString = "https://ghostpii.com/api/hash/?wordLength="+String(encodedStr.count)
                
                urlString += "&blobData=" + String(myTimestamp!)
                urlString += "&n=50000"
                //We need to figure out how we do the random seeds here
                urlString += "&seed=" + "42069"
                let hashURL = URL(string: urlString)!
                var hashRequest = URLRequest(url: hashURL)
                hashRequest.httpMethod = "GET"
                
                
                let hashTask = session.dataTask(with: hashRequest){ data,response,error in
                    guard let data = data, error == nil else {
                        print(error?.localizedDescription ?? "No data")
                        return
                    }
                    
                    let str = String(data: data, encoding: .utf8)!
                    print(str)
                    
                    let unparsedHashData = try! JSONDecoder().decode([unparsedHashInfo].self, from: data)
                    let hashData = hashInfo(info: unparsedHashData[0])
                    print(hashData)
                    completion(true, hashData)
                    
                }.resume()
                
            }.resume()
            
        }
    }
    
}

func performSignup(username: String, email:String, completion: @escaping (_ success: Bool, _ data: hashInfo) -> Void) async{
    
    var signupURL = URL(string: "https://ghostpii.com/user-signup/")!
    var getSignup = URLRequest(url: signupURL)
    
    let config = URLSessionConfiguration.default
    config.httpShouldSetCookies = true
    let session = URLSession.init(configuration: config)
    
    let dataTask = session.dataTask(with: getSignup) { data, response, error in
        guard let data = data, error == nil else {
            print(error?.localizedDescription ?? "No data")
            return
        }
        
        print(session.configuration.httpCookieStorage!.cookies![0].value)
        let str = String(data: data, encoding: .utf8)!
        
        let middlewareToken = HTMLParser().parseForMiddlewareToken(html: str)
        print("MIDDLEWARE")
        print(middlewareToken)
        
        let parameters: [String: Any] = ["username":username, "email":email, "csrfmiddlewaretoken" : middlewareToken]
        
        
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        
        var signupURL = URL(string: "https://ghostpii.com/user-signup/")!
        
        var postRequest = URLRequest(url: signupURL)
        postRequest.httpMethod = "POST"
        postRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        postRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        postRequest.addValue("max-age=0", forHTTPHeaderField: "CACHE-CONTROL")
        postRequest.httpBody = parameters.percentEncoded()
        
        
        let dataTask2 = session.dataTask(with: postRequest) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            
            let str = String(data: data, encoding: .utf8)!
            print(response)
            print(str)
            
            
        }.resume()
        
        
    }.resume()
}

func computeHash(hashStr : String, hashInfo: hashInfo) -> Int {
    
    let decodedNums = decodeCiphertext(cipherString: hashStr)
    
    var weightedCipherList = [Int]()
    
    for i in 0..<hashInfo.coefficients.count {
        weightedCipherList.append(decodedNums[i]*hashInfo.coefficients[i])
    }
    
    
    return (weightedCipherList.reduce(0, +) - hashInfo.computed_range_sum) % hashInfo.prime
}

//MARK: - Ciphertext methods

//takes a row of encrypted values and converts it to ciphertext
func createCiphertext(encryptedVals: [Int]) -> String {
    let     admChars = ["!", "\"", "#", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "]", "^", "_", "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
    
    var cipherWord = ""
        
    for encryptedVal in encryptedVals {
        var trigram = ""
        var interim = encryptedVal
        for _ in 0..<3 {
            let residue = interim % 87
            interim = Int((interim - residue)/87)
            trigram = trigram + admChars[residue]
        }
        cipherWord = cipherWord + trigram
    }
    
    return  cipherWord

}

func decodeCiphertext(cipherString : String) -> [Int]{
    let  admChars = ["!", "\"", "#", "%", "&", "'", "(", ")", "*", "+", ",", "-", ".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", "@", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "[", "]", "^", "_", "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
    print(cipherString)
    var decodedList = [Int]()
    for i in stride(from: 0, to: cipherString.count, by: 3){
        let trigram = cipherString.dropFirst(i).prefix(3)
        var encodedChar = 0
        for j in 0..<3 {
            let curChar = String(trigram.dropFirst(j).prefix(1))
            let charIndex = admChars.firstIndex(of: curChar)!
            encodedChar = encodedChar + (charIndex * (87 ^^ j))
            
        }
        decodedList.append(encodedChar)
    }
    return decodedList
}

// MARK: - Structs
struct encryptKey : Codable{
    var id : Int
    var atom_key : Int
    var atom_key_inv : Int
    
    init(id: Int, atom_key: Int, atom_key_inv: Int) {
        self.id = id
        self.atom_key = atom_key
        self.atom_key_inv = atom_key_inv
    }
}

struct userData : Codable{
    var url : String
    var username : String
    var email : String
}

struct stateInfo : Codable{
    var owner : Int
    var minId : Int
    var maxId : Int
}

struct unparsedHashInfo : Codable{
    var base_id: Int
    var computed_range_sum: Int
    var coefficients: String
    var prime: Int
    
}

struct hashInfo {
    var base_id: Int
    var computed_range_sum: Int
    var coefficients: [Int]
    var prime: Int
    
    init(info : unparsedHashInfo) {
        self.base_id = info.base_id
        self.computed_range_sum = info.computed_range_sum
        self.prime = info.prime
        var strCoeffs = info.coefficients
        
        strCoeffs.removeFirst()
        strCoeffs.removeLast()
        
        let separatedNums = strCoeffs.components(separatedBy: ",")
        
        self.coefficients = [Int]()
        
        for num in separatedNums {
            self.coefficients.append(Int(num.trimmingCharacters(in: .whitespaces))!)
        }
    }
    
}

struct DefaultsKeys {
    static let token = "firstStringKey"
    static let username = "secondStringKey"
    static let hash = 0
}

// MARK: - Extensions and overloads

extension StringProtocol {
    var asciiValues: [UInt8] { compactMap(\.asciiValue) }
}

precedencegroup PowerPrecedence { higherThan: MultiplicationPrecedence }
infix operator ^^ : PowerPrecedence
func ^^ (radix: Int, power: Int) -> Int {
    return Int(pow(Double(radix), Double(power)))
}

func ascii2String(asciiVals: [Int]) -> String {
    var newStr = ""
    for val in asciiVals{
        newStr += String(UnicodeScalar(val)!)
    }
    return newStr
}

extension Dictionary {
    func percentEncoded() -> Data? {
        map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed: CharacterSet = .urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
