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
  
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target  = '10.13'

  s.frameworks = 'Foundation'
  
  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.frameworks = 'CoreData'
    core.source_files = 'Flapjack/Core/**/*.swift'

    core.test_spec 'Tests' do |tests|
      tests.source_files = 'Tests/Core/**/*.swift'
    end
  end

  s.subspec 'CoreData' do |core_data|
    core_data.dependency 'Flapjack/Core'
    core_data.frameworks = 'CoreData'
    core_data.source_files = 'Flapjack/CoreData/**/*'

    core_data.test_spec 'Tests' do |tests|
      base_path = 'Tests/CoreData'
      tests.source_files = [File.join(base_path, '**/*.swift')]
      tests.resource_bundle = { 'FlapjackCoreDataTests' => File.join(base_path, 'Resources/**/*') }
      tests.preserve_paths = [File.join(base_path, 'Resources/TestModel.xcdatamodeld')]
    end
  end
  
  s.subspec 'UIKit' do |uikit|
    uikit.dependency 'Flapjack/Core'
    uikit.frameworks = 'UIKit'
    uikit.source_files = 'Flapjack/UIKit/**/*'
  end
end
