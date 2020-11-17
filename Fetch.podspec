#
# Be sure to run `pod lib lint Fetch.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Fetch'
  s.version          = '2.3.0'
  s.summary          = 'A resource based network abstraction based on Alamofire'


  s.description      = <<-DESC
  'A resource based network abstraction based on Alamofire'
                       DESC
  s.homepage         = 'https://github.com/allaboutapps/Fetch'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'https://www.allaboutapps.at' => 'office@allaboutapps.at' }
  s.source           = { :git => 'https://github.com/allaboutapps/Fetch.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.source_files = 'Fetch/Code/**/*.swift'
  s.platforms = {
      "ios": "11.0"
  }
  
  s.dependency 'Alamofire', '~> 5.0.0-rc.2'

end
