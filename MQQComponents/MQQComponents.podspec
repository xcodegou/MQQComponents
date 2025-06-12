Pod::Spec.new do |s|
  
  s.name         = "MQQComponents"
  s.version      = "2.0.0"
  s.summary      = "MQQComponents 通用组件"
  s.description  = <<-DESC
                    MQQComponents - 通用组件
                    DESC
  s.homepage     = "https://git.code.oa.com/wspd_ep-iOS/MQQComponents"
  s.license      = { :type => "", :file => "LICENSE" }
  s.author       = { "kloudzliang" => "kloudzliang@tencent.com" }
    
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  
  s.source       = { :git => "https://git.code.oa.com/wspd_ep-iOS/MQQComponents.git", :tag => s.version.to_s }
  s.requires_arc = false
  
  s.frameworks   = "Foundation", "CoreFoundation"
  s.libraries    = "c", "c++"
  
  s.subspec "MQQFoundation" do |ss|
    ss.source_files = "MQQComponents/MQQFoundation/**/*.{h,m,mm}"
    ss.public_header_files = "MQQComponents/MQQFoundation/**/*.h"
    ss.ios.deployment_target = "8.0"
    ss.osx.deployment_target = "10.10"
    ss.watchos.deployment_target = "2.0"
  end
  
  s.subspec "MQQUserDefaults" do |ss|
    ss.source_files = "MQQComponents/MQQUserDefaults/**/*.{h,m,mm}"
    ss.public_header_files = "MQQComponents/MQQUserDefaults/**/*.h"
    ss.ios.frameworks = "UIKit"
  end
  
  s.subspec "MQQDatabase" do |ss|
    ss.source_files = "MQQComponents/MQQDatabase/**/*.{h,m,mm}"
    ss.public_header_files = "MQQComponents/MQQDatabase/**/*.h"
    ss.libraries = "sqlite3.0"
  end
  
  s.subspec "MQQNetworkInfo" do |ss|
    ss.source_files = "MQQComponents/MQQNetworkInfo/**/*.{h,m,mm}"
    ss.exclude_files = "MQQComponents/MQQNetworkInfo/MQQNetworkInfo+DNS.{h,m}"
    ss.public_header_files = "MQQComponents/MQQNetworkInfo/**/*.h"
    ss.frameworks = "CoreTelephony", "SystemConfiguration"
  end
  
  s.subspec "MQQSubstrate" do |ss|
    ss.source_files = "MQQComponents/MQQSubstrate/**/*.{h,m,mm}"
    ss.public_header_files = "MQQComponents/MQQSubstrate/**/*.h"
  end
end
