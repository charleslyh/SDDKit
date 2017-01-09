Pod::Spec.new do |s|
  s.name         = "SDDKit"
  s.version      = "1.1.1"
  s.license      = "MIT"
  s.summary      = "Easiest way for implementing hierarchical state machine(HSM) based programs in Objective-C."
  s.homepage     = "https://github.com/charleslyh/SDDKit"
  s.authors      = { 'Charles Lee' => 'charles.liyh@gmail.com' }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/charleslyh/SDDKit.git", :tag => s.version }
  s.requires_arc = true

  s.source_files = 'SDDKit', 'SDDKit/**/*.{m,c,h}'
  s.public_header_files = 'SDDKit/SDDKit.h', 'SDDKit/SDD{EventsPool,Scheduler,SchedulerBuilder}.h'
end
