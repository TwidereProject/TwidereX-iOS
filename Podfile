source 'https://cdn.cocoapods.org/'
platform :ios, '13.0'

target 'TwidereX' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for TwidereX
  
  ## UI
  pod 'Floaty', '~> 4.2.0'
  
  # misc
  pod 'SwiftGen', '~> 6.3.0'
  pod 'DateToolsSwift', '~> 5.0.0'
  pod 'Firebase/Analytics'

  # Twitter
  pod 'twitter-text', '~> 3.1.0'
  
  target 'TwidereXTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'TwidereXUITests' do
    # Pods for testing
  end

end

plugin 'cocoapods-keys', {
  :project => "TwidereX",
  :keys => [
    "app_secret",
    "consumer_key",
    "consumer_key_secret",
    "host_key_public",
    "oauth_endpoint",
    "oauth_endpoint_debug",
    "firebase_client_id",
    "firebase_api_key",
    "firebase_gcm_sender_id",
    "firebase_bundle_id",
    "firebase_project_id",
    "firebase_storage_bucket",
    "firebase_google_app_id",
    "firebase_database_url"
  ]
}
