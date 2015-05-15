Pod::Spec.new do |s|
  s.name             = 'Helium'
  s.version          = '0.0.1'
  s.summary          = 'An Android-like layout inflation and bucketed resource library.'
  s.homepage         = 'https://github.com/AlexQuinlivan/Helium'
  s.license          = 'Apache License, Version 2.0'
  s.author           = { 'Alex Quinlivan' => 'alex@quinlivan.co.nz' }
  s.source           = { :git => 'https://github.com/AlexQuinlivan/Helium.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/quin1212'
  s.platform      = :ios, '7.0'
  s.requires_arc  = true
  s.source_files  = 'Pod/Classes/**/*'
  s.resource = 'Pod/Resources/helium_res.bundle'
  s.dependency 'EDSemver', '~> 0.3.0'
  s.dependency 'GDataXML-HTML', '~> 1.2.0'
  s.library = 'xml2'
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
end
