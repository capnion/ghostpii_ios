//
//  DateInfo.swift
//  PrivacyTest
//
//  Created by Jack Phillips on 5/10/23.
//

import Foundation


struct DateInfo{
    
    var docID:String
    
    var date:String
    var dateBounds:Array<Any>
    var flowRate:Int
    var flowRateIndex:Int
    var username:String
    var usernameBounds:Array<Any>
    
    
    
}


struct MeetingInfo{
    var docID:String
    
    var date:String
    var dateHash:Int
    var dateBounds:[Int]
    
    var username:String
    var usernameBounds:[Int]
    
    var description:String
    var descBounds:[Int]
}

//
