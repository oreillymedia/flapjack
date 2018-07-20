Pod::Spec.new do |s|
  s.name             = 'Flapjack'
  s.version          = '0.1.0'
  s.summary          = 'A short description of Flapjack.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://github.com/oreillymedia/flapjack'
  s.license          = { type: 'MIT', file: 'LICENSE' }
  s.author           = { 'Ben Kreeger' => 'bkreeger@oreilly.com' }
  s.source           = { git: 'https://github.com/oreillymedia/flapjack.git', tag: s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target  = '10.12'
  s.source_files = 'Flapjack/Core/**/*'
  s.frameworks = 'Foundation'
  
  s.subspec 'CoreData' do |core_data|
    core_data.frameworks = 'CoreData'
    core_data.source_files = 'Flapjack/CoreData/**/*'
  end
end
