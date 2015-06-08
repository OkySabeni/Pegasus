# Uncomment this line to define a global platform for your project
platform :ios, '7.0'

target 'Pegasus' do
	pod 'VIMNetworking', '5.4.2'
	pod 'VIMObjectMapper', '5.4.2'
	pod 'AFNetworking', '2.5.4'
    pod 'VIMVideoPlayer', '5.4.2'
end

target 'PegasusTests' do

end

target 'PegasusExtension' do
	pod 'VIMNetworking', '5.4.2'
	pod 'VIMObjectMapper', '5.4.2'
	pod 'AFNetworking', '2.5.4'
end

post_install do |installer_representation|
    installer_representation.project.targets.each do |target|
        if target.name == "Pods-PegasusExtension-AFNetworking"
            target.build_configurations.each do |config|
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'AF_APP_EXTENSIONS=1']
            end
        end
    end
end