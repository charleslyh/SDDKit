Pod::Spec.new do |s|
  s.name         = "SDDKit"
  s.version      = "1.0.4"
  s.summary      = "Fastest way for implementing hierarchical state machine(HSM) based programs in Objective-C."
  s.description  = "Fastest way for implementing hierarchical state based programs in Objective-C. Including built-in supports like readable DSL parser, event dispatcher, a visual macOS monitor program, etc."
  s.homepage     = "https://github.com/charleslyh/SDDKit"
  s.license      = "MIT"
  s.author       = "CharlesLyh"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/charleslyh/SDDKit.git", :tag => "1.0.4" }
  s.source_files = "SDD", "SDD/SDD/**/*.{h,c,m}", "SDD/SDDI/**/*.{h,m}"
  s.requires_arc = true
end
