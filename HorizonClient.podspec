Pod::Spec.new do |s|
  s.name             = "HorizonClient"
  s.version          = "3.0.2"
  s.summary          = "Cliente do Horizon para iOS."
  s.homepage         = "https://github.com/globoi/horizon-client-ios-bin-releases"
  s.author           = { "Globo.com" => "bigdata.pipeline@corp.globo.com" }
  s.swift_version    = "4.2"
  s.source           = { :git => "https://github.com/globoi/horizon-client-ios-bin-releases.git", :tag => s.version.to_s }
  s.ios.deployment_target = "9.0"
  s.tvos.deployment_target = "9.0"

  s.framework = "Foundation"

  s.requires_arc = true

  s.vendored_frameworks = 'Framework/HorizonClient.xcframework'
end
