source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '9.0'
inhibit_all_warnings!
use_frameworks!

def installablePods
    pod "RealmSwift"
    pod "Alamofire"
    pod "ObjectiveCloudant"
end

target 'Starter App' do
    installablePods
end

post_install do |installer|
    installer.pods_project.root_object.attributes["ORGANIZATIONNAME"] = "IBM"
end
