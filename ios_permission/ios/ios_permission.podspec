#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint ios_permission.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'ios_permission'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for native iOS camera and location permission handling.'
  s.description      = <<-DESC
A Flutter plugin that provides reliable, native iOS camera and location permission handling
that bypasses the unreliable permission_handler plugin. It uses direct platform APIs for
maximum reliability and comprehensive permission status information.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
