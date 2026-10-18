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
                   
  spec.homepage     = "https://github.com/Yuan-l/MyOpenWeatherPlus.git"
    
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  spec.author             = { "Yuan-l" => "1013540016@qq.com" }

  spec.source       = { :git => "https://github.com/Yuan-l/MyOpenWeatherPlus.git", :tag => spec.version.to_s }

#  spec.subspec 'Core' do |core|
#    core.source_files  = "Classess", "Classess/**/*.{h,m,swift}"
#    core.dependency 'Masonry'
#    core.dependency 'DateTools'
#    core.dependency 'ReactiveObjC'
#    core.dependency 'YYText'
#    core.dependency 'YYCache'
#    core.dependency 'FDFullscreenPopGesture'
#    core.dependency 'QMUIKit'
#    core.dependency 'CocoaLumberjack'
#    core.dependency 'AMapLocation'
#    core.dependency 'MJRefresh'
#    core.dependency 'YYModel'
#    core.dependency 'AFNetworking'
#  end
#  
#  spec.subspec 'QWeather' do |sss|
#    sss.dependency 'MyOpenWeatherPlus/Core'
#    sss.source_files            = 'Classes/Helpers/*'
#    sss.ios.vendored_frameworks = 'Classes/Helpers/*.framework'
#    sss.ios.vendored_library    = 'Classes/Helpers/*.a'
#    sss.xcconfig = {
#        'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/MyOpenWeatherPlus/Classes/Helpers'
#    }
#  end
#  
#  spec.default_subspec = 'QWeather'
  
  spec.source_files  = "Classess", "Classess/**/*.{h,m,swift}"
  spec.dependency 'Masonry'
  spec.dependency 'DateTools'
  spec.dependency 'ReactiveObjC'
  spec.dependency 'YYText'
  spec.dependency 'YYCache'
  spec.dependency 'FDFullscreenPopGesture'
  spec.dependency 'QMUIKit'
  spec.dependency 'CocoaLumberjack'
  spec.dependency 'AMapLocation'
  spec.dependency 'MJRefresh'
  spec.dependency 'YYModel'
  spec.dependency 'AFNetworking'
  
  spec.vendored_frameworks = 'Framework/QWeather.framework'
  spec.vendored_libraries = 'Framework/libPods-OpenWeatherPlus.a'
  spec.xcconfig = {
      'FRAMEWORK_SEARCH_PATHS' => '$(PODS_ROOT)/MyOpenWeatherPlus/Framework'
  }
  
  spec.static_framework = true
end
