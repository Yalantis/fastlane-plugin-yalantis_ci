describe Fastlane::Actions::YalantisCiAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The yalantis_ci plugin is working!")

      Fastlane::Actions::YalantisCiAction.run(nil)
    end
  end
end
