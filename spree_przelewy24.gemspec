# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_przelewy24'
  s.version     = '1.0.0'
  s.summary     = 'Przelewy24 payment system for Spree'
  #s.description = 'Add (optional) gem description here'
  s.required_ruby_version = '>= 2.5.0'

  s.author            = 'Grzegorz Brzezinka'
  s.email             = 'info@matfiz.com.pl'
  s.homepage          = 'https://github.com/matfiz/spree_przelewy24'
  # s.rubyforge_project = 'actionmailer'

  s.files        = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency('deface')
  s.add_dependency('faraday')
  s.add_dependency('openssl')

  spree_version = '>= 3.6.0', '< 5.0'
  s.add_dependency 'spree_backend', spree_version
  s.add_dependency 'spree_core', spree_version
  # s.add_dependency 'spree_frontend', spree_version
  s.add_dependency 'spree_auth_devise'
end
