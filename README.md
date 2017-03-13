# Starter iOS App

## Introduction
The starter app has the ability to pull data from HealthKit, store it locally, and sync with the server. As an added bonus, the iOS application can also read in data from CSV files (in a specific format) and store it locally.

## Prerequisites
1. [CocoaPods](https://cocoapods.org/)

## Setup
1. Run `pod install` in the root directory of the project
2. Open the `.xcworkspace` file and Build & Run

## Architecture
Three operations will occur when the app is launched:
- Sync with Server (`ServerSync.swift`)
- Sync with HealthKit (`HealthKitSync.swift`)
- Download and Store CSV Data (`CSVDataSync.swift`)

### HealthKitSync.swift
Check out `HealthKitSync.swift` and `HealthKitManager.swift` to see how we are working with HealthKit. 

HealthKitSync pulls data down from HealthKit and stores it in Realm; it will not push data into HealthKit. If you would like to store data into HealthKit, check out `saveRealmData_ToHealthKit()` in `HealthKitSync.swift`.

If you would like to add support for handling new data types from HealthKit, do a project wide search for this text `//TODO-ADD-NEW-DATA-TYPE`. These are all the places where you would need to add new strings, constants, logic, and etc for your new data type.

### ServerSync.swift
If you are including a server component into your system, the app will sync all data with the NodeJS/CloudantDB server. See the [Starter NodeJS](https://github.com/health-hacks/starter-nodejs-server) page for more information on getting that setup.

Check out `ServerSync.swift` to see more details. We are using the [swift-cloudant](https://github.com/cloudant/swift-cloudant) library to facilitate pulling down and store objects in the CloudantDB (on our NodeJS server).

**Setup**

Create a new set of credentials in your Cloudant DB Admin page or use the one that was created during the `Starter NodeJS` setup. Fill out these credentials in `ServerSync.swift`.

### Download and Store CSV Data
We also download and store CSV data in Realm (which gets synced up to the server) when you specify CSV files in the `urlsArr` in `CSVDataSync.swift`. The CSV data must be in a specific [format](https://healthhacks.gitbooks.io/developer/content/datasets_overview.html) to get parsed.

## Data

### Realm
The database we are using for local storage is Realm: http://realm.io. You should check it out even if you are not using the starter apps!

### Data Model
The data model only consists of two model classes: `HealthData` and `HealthDataModel`. Although this seems generic and simplistic, it allows us to store data from almost all data types.

**HealthData**
```
class HealthData: Object {
    dynamic var id: String = UUID().uuidString
    dynamic var source: String = ""
    dynamic var date: Date = Date()
    dynamic var type: String = ""
    
    dynamic var participantId: String = ""
    dynamic var sessionId: String?
    
    let dataObjects = LinkingObjects(fromType: HealthDataValue.self, property: "healthObject")
}
```

`HealthData` stores generic health information (e.g. date, type, source, etc). This object does not store the actual data values; this is persisted in `HealthDataValue`. `HealthData` is loosely linked with `HealthDataValue` through [LinkingObjects](https://realm.io/docs/swift/latest/#inverse-relationships).


***

**HealthDataValue**
```
class HealthDataValue: Object { 
    dynamic var healthObject: HealthData?
    dynamic var label: String?
    dynamic var value: String?
}
```

`HealthDataValue` stores specific health values and labels for those values. It's linked to a `HealthData` object.

***

**DataDownloadRecord**

```
class DataDownloadRecord: Object {
    dynamic var url: String?
    dynamic var date: NSDate?
}
```

DataDownloadRecord is used to keep track of the CSV files have been downloaded. This is to make sure we do not download the CSV file twice on app launch.
