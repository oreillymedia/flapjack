Pod::Spec.new do |s|
  s.name        = 'Flapjack'
  s.version     = '0.6.1'
  s.summary     = 'A Swift data persistence API with support for Core Data.'
  s.description = <<-DESC
Flapjack is an iOS/macOS/tvOS framework with 2 primary goals.

1. Help you abstract your model-focused database persistence layer from the rest
   of your app
2. Simplify the database layer's API into an easy-to-use, easy-to-remember, full
   Swift one

It lets you skip the boilerplate commonly associated with database layers like
Core Data and lets you introduce structured, sane data persistence in your app
sooner, letting you spend more of your time creating the app you really want. We
use it at O'Reilly Media and Safari Books Online for our iOS apps, and if you
like what you see, perhaps you will too.
                       DESC
  s.homepage    = 'https://github.com/oreillymedia/flapjack'
  s.license     = { type: 'MIT', file: 'LICENSE' }
  s.author      = { 'Ben Kreeger' => 'bkreeger@oreilly.com' }
  s.source      = {
    git: 'https://github.com/oreillymedia/flapjack.git',
    tag: s.version.to_s
  }

  s.ios.deployment_target  = '11.0'
  s.tvos.deployment_target = '11.0'
  s.osx.deployment_target  = '10.13'

  s.frameworks = 'Foundation'
  s.swift_version = '5.0'

  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.frameworks = 'CoreData'
    core.source_files = 'Flapjack/Core/**/*.swift'
  end

  s.subspec 'CoreData' do |core_data|
    core_data.dependency 'Flapjack/Core'
    core_data.frameworks = 'CoreData'
    core_data.source_files = 'Flapjack/CoreData/**/*'
  end

  s.subspec 'UIKit' do |uikit|
    uikit.dependency 'Flapjack/Core'
    uikit.ios.frameworks = 'UIKit'
    uikit.ios.source_files = 'Flapjack/UIKit/**/*'
  end
end
