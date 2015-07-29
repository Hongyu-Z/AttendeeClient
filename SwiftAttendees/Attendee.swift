//
//  Attendee.swift
//  SwiftAttendeeCollector
//
//  Created by Zhu, Hongyu on 7/27/15.
//  Copyright (c) 2015 Zhu, Hongyu. All rights reserved.
//

import Foundation


class Attendee: NSObject, NSCoding {
    
    var firstName: String!
    var lastName:  String!
    var headLine: String!
//    var attendeeTypeID: String!
    var id: String!
    var profile: String!
    
    // initialize
    init(firstName first: String = "", lastName last: String, headLine head: String, attendeeID id: String = "") {
        super.init()
        self.headLine = head
        firstName = first
        lastName = last
//        attendeeTypeID = typeID
        self.id = id
        self.profile = "first name:" + first + " last name:" + last + " headline:"+head+" id:"+id
    }
    
    // returns the attendee's information in JSON format
    func jsonFormat() -> String {
        
        var body = "{ "
        body += "\"FirstName\": \"" + firstName + "\", "
        body += "\"LastName\": \"" + lastName + "\", "
//        body += "\"AttendeeTypeID\": \"" + attendeeTypeID + "\" }"
        body += "}"
        return body
    }
    
    func encodeWithCoder(aCoder: NSCoder){
        aCoder.encodeObject(self.firstName, forKey: "firstName")
        aCoder.encodeObject(self.lastName, forKey: "lastName")
        aCoder.encodeObject(self.headLine, forKey: "headLine")
        aCoder.encodeObject(self.id, forKey: "id")
    }
    required init(coder aDecoder: NSCoder){
        self.firstName = aDecoder.decodeObjectForKey("name") as! String
        self.lastName = self.firstName
        self.headLine = aDecoder.decodeObjectForKey("title") as! String
        self.id = aDecoder.decodeObjectForKey("id") as! String
    }
}