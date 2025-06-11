source 'https://github.com/CocoaPods/Specs.git'
platform :ios, "15.0"

def main_pods
    # Modern networking
    pod 'Alamofire'
    
    # Image loading and caching for Flickr images
    pod 'Kingfisher'
    
    # JSON parsing
    pod 'SwiftyJSON'
end

target 'SleepMate' do
    use_frameworks!
    main_pods
end

target 'SleepMate Tests' do
    use_frameworks!
    main_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '5.0'
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        end
    end
end
