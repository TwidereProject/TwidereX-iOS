source 'https://cdn.cocoapods.org/'
platform :ios, '15.0'

target 'TwidereX' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  # Debug
  pod 'LookinServer', :subspecs => ['SwiftAndNoHook'], :configurations => ['Debug']
  
  ## UI
  pod 'XLPagerTabStrip', '~> 9.0.0'
  
  # Firebase
  pod 'Firebase/AnalyticsWithoutAdIdSupport'
  pod 'FirebaseCrashlytics'
  pod 'FirebasePerformance'
  pod 'FirebaseMessaging'
  
  # misc
  pod 'SwiftGen', '~> 6.6.2'
  pod 'Sourcery', '~> 1.8.1'
  
  target 'TwidereXTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'TwidereXUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
