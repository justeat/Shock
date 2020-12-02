#
# Be sure to run `pod lib lint Shock.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Shock'
  s.version          = '5.1.0'
  s.summary          = 'A HTTP mocking framework written in Swift.'

  s.description      = <<-DESC
Shock lets you quickly and painlessly provided mock responses for HTTP & HTTPs web requests made by your iOS app.
                       DESC

  s.homepage         = 'https://github.com/justeat/Shock'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'Jack Newcombe' => 'jack.newcombe@just-eat.com' }
  s.source           = { :git => 'https://github.com/justeat/Shock.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/justeat_tech'

  s.ios.deployment_target = '10.0'
  s.swift_version = '5.0'

  s.source_files =
  'Shock/Classes/**/*',
  'Shock/Classes/NIO/**/*'

  s.dependency 'SwiftNIOHTTP1', '~> 2.22.1'
  s.dependency 'GRMustache.swift', '~> 4.0.1'
end
