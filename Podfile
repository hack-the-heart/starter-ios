source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '9.0'
inhibit_all_warnings!
use_frameworks!

def installablePods
    pod "RealmSwift"
    pod "Alamofire", "~> 4.0"
    pod "ObjectiveCloudant"
	pod "CHCSVParser"
end

target 'Starter App' do
    installablePods
end

post_install do |installer|
    installer.pods_project.root_object.attributes["ORGANIZATIONNAME"] = "IBM"
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
