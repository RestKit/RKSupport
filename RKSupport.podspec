Pod::Spec.new do |s|
  s.name     = 'RKSupport'
  s.version  = '1.0.0'
  s.license  = 'Apache2'
  s.summary  = 'A collection of support classes extracted from RestKit.'
  s.homepage = 'https://github.com/RestKit/RKSupport'
  s.authors  = { 'Kurry Tran' => 'kurry.tran@gmail', 'Blake Watters' => 'blakewatters@gmail.com' }
  s.source   = { :git => 'https://github.com/RestKit/RKSupport.git', :tag => "v#{s.version}" }
  s.source_files = 'Code'
  s.requires_arc = true

  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  
  s.default_subspec = 'All'
  
  s.subspec 'All' do |ss|    
    ss.dependency 'RKSupport/RKPathTemplate'
    ss.dependency 'RKSupport/RKParameterConstraint'
  end
  
  s.subspec 'RKPathTemplate' do |ss|
    ss.source_files   = 'Code/RKPathTemplate/*'
  end
  
  s.subspec 'RKParameterConstraint' do |ss|
    ss.source_files   = 'Code/RKParameterConstraint/*'
  end
end
