Pod::Spec.new do |s|
	s.name = 'JSQMessagesViewController-Fork'
	s.version = '7.4.0'
	s.summary = 'A forked version of JSQMessagesViewController. An elegant messages UI library for iOS.'
	s.homepage = 'http://jessesquires.github.io/JSQMessagesViewController'
	s.license = 'MIT'
	s.platform = :ios, '9.0'

	s.author = 'Jesse Squires'
	s.social_media_url = 'https://twitter.com/jesse_squires'

	s.source = { :git => 'https://github.com/alexburkhay/JSQMessagesViewController.git', :tag => s.version }
	s.source_files = 'JSQMessagesViewController/**/*.{h,m}'

	s.resources = ['JSQMessagesViewController/Assets/JSQMessagesAssets.bundle', 'JSQMessagesViewController/**/*.{xib}']

	s.frameworks = 'QuartzCore', 'CoreGraphics', 'CoreLocation', 'MapKit', 'AVFoundation'
	s.requires_arc = true

	s.dependency 'JSQSystemSoundPlayer', '~> 2.0.1'
	
	s.deprecated = true
end
