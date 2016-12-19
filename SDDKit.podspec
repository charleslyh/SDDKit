Pod::Spec.new do |s|
  s.name         = "SDDKit"
  s.version      = "1.0.5"
  s.license      = "MIT"
  s.summary      = "Easiest way for implementing hierarchical state machine(HSM) based programs in Objective-C."
  s.homepage     = "https://github.com/charleslyh/SDDKit"
  s.authors      = { 'Charles Lee' => 'charles.liyh@gmail.com' }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/charleslyh/SDDKit.git", :tag => s.version, :submodules => true }
  s.requires_arc = true

  s.public_header_files = 'SDDKit/SDDKit.h'
  s.source_files = 'SDDKit/SDDKit.h'

  s.subspec 'Core' do |ss|
    ss.source_files = 'SDDKit/lex.yy.c', 'SDDKit/y.tab.{h,c}', 'SDDKit/sdd_*.{h,c}'
  end

  s.subspec 'Parser' do |ss|
    ss.source_files = 'SDDKit', 'SDDKit/SDD{EventsPool,Scheduler,SchedulerBuilder}.{h.m}'
    ss.public_header_files = 'SDDKit/SDD{EventsPool,Scheduler,SchedulerBuilder}.h'
  end

end
