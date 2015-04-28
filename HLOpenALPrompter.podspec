#
# Be sure to run `pod lib lint HLOpenALPrompter.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "HLOpenALPrompter"
  s.version          = "0.2.1"
  s.summary          = "HLOpenALPrompter is a wrapper for playing sound by OpenAL"
  s.description      = <<-DESC
                       HLOpenALPrompter let you easily play sound through OpenAL.
                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/Invisibi/HLOpenALPrompter"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "KenKuan" => "kenkuan@hooloop.com" }
  s.source           = { :git => "https://github.com/Invisibi/HLOpenALPrompter.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'HLOpenALPrompter' => ['Pod/Assets/*.png']
  }

  s.frameworks = 'OpenAL'
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.dependency 'AFNetworking', '~> 2.3'
end
