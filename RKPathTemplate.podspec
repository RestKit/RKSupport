Pod::Spec.new do |s|
  s.name     = 'RKPathTemplate'
  s.version  = '1.0.0'
  s.license  = 'Apache2'
  s.summary  = 'A simple library for matching paths containing variable components.'
  s.homepage = 'https://github.com/RestKit/RKPathTemplate'
  s.authors  = { 'Kurry Tran' => 'kurry.tran@gmail', 'Blake Watters' => 'blakewatters@gmail.com' }
  s.source   = { :git => 'https://github.com/RestKit/RKPathTemplate.git', :tag => "v#{s.version}" }
  s.source_files = 'Code'
  s.requires_arc = true

  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
end
