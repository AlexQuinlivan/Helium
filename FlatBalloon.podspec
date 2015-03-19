#
# Be sure to run `pod lib lint FlatBalloon.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
# TODO: this
Pod::Spec.new do |s|
  s.name             = 'FlatBalloon'
  s.version          = '0.0.1'
  s.summary          = 'An Android-like layout inflation and bucketed resource library.'
  s.homepage         = 'https://github.com/AlexQuinlivan/FlatBalloon'
  s.license          = 'Apache License, Version 2.0'
  s.author           = { 'Alex Quinlivan' => 'alex@quinlivan.co.nz' }
  s.source           = { :git => 'https://github.com/AlexQuinlivan/FlatBalloon.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/AlexQuinlivan'
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'
  s.dependency 'EDSemver', '~> 0.3.0'
end
