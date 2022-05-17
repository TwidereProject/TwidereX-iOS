source 'https://cdn.cocoapods.org/'
platform :ios, '15.0'

def common_pods
  # Misc
  pod 'DateToolsSwift', '~> 5.0.0'
  # Twitter
  pod 'twitter-text', '~> 3.1.0'
end

target 'TwidereX' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TwidereX
  common_pods
  
  ## UI
  pod 'XLPagerTabStrip', '~> 9.0.0'
  
  # Firebase
  pod 'Firebase/AnalyticsWithoutAdIdSupport'
  pod 'FirebaseCrashlytics'
  pod 'FirebasePerformance'
  
  # misc
  pod 'SwiftGen', '~> 6.3.0'
  pod 'Sourcery', '~> 1.6.1'

  # Debug
  pod 'FLEX', '~> 4.4.0', :configurations => ['Debug']
  pod 'ZIPFoundation', '~> 0.9.11', :configurations => ['Debug']
  
  target 'TwidereXTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'TwidereXUITests' do
    # Pods for testing
  end

end

target 'AppShared' do 
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  common_pods
end

# target 'ShareExtension' do 
#   # Comment the next line if you don't want to use dynamic frameworks
#   use_frameworks!
# end

plugin 'cocoapods-keys', {
  :project => "TwidereX",
  :keys => [
    "app_secret",
    "consumer_key",
    "consumer_key_secret",
    "client_id",
    "client_id_debug",
    "host_key_public",
    "oauth_endpoint",
    "oauth_endpoint_debug",
    "oauth2_endpoint",
    "oauth2_endpoint_debug"
  ]
}

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
