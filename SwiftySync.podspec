Pod::Spec.new do |s|
  s.name             = "SwiftySync"
  s.version          = "0.9"
  s.summary          = "Set of tools to sync a collection of data up to a remote source, or down from a remote location"
  s.homepage         = "https://github.com/lacyrhoades/SwiftySync"
  s.license          = { type: 'MIT', file: 'LICENSE' }
  s.author           = { "Lacy Rhoades" => "lacy@colordeaf.net" }
  s.source           = { git: "https://github.com/lacyrhoades/SwiftySync.git" }
  s.ios.deployment_target = '10.0'
  s.requires_arc = true
  s.ios.source_files = 'Source/**/*'
  s.dependency "SwiftyDropbox"
  s.dependency "TOSMBClient"
end
