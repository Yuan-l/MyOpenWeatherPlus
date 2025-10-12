#
#  Be sure to run `pod spec lint MyOpenWeatherPlus.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "MyOpenWeatherPlus"
  spec.version      = "0.0.1"
  spec.summary      = "A short description of MyOpenWeatherPlus."

  spec.description  = <<-DESC
      "iOS创建TBCustomNetworkLogger库"
                   DESC
                   
  spec.ios.deployment_target = "13.0"

  spec.homepage     = "https://github.com/1013540016@qq.com/MyOpenWeatherPlus"
    
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  spec.author             = { "Yuan-l" => "1013540016@qq.com" }

  spec.source       = { :git => "https://github.com/1013540016@qq.com/MyOpenWeatherPlus.git", :tag => spec.version.to_s }

  spec.source_files  = "Classess", "Classess/**/*.{h,m,swift}"

  spec.static_framework = true
end
