# frozen_string_literal: true

module Decidim::SpamSignal::Admin
  describe UpdateConfigCommand do
    let(:organization) { create(:organization) }
    let(:config) { Decidim::SpamSignal::Config.get_config(organization) }
    it "raises an error if no forms are submitted" do
      expect do
        UpdateConfigCommand.call(
          config,
          nil,
          [],
          []
        )
      end.to raise_error Decidim::SpamSignal::Error
    end

    it "update! config attributes with the ConfigForm" do
      form = Decidim::SpamSignal::ConfigForm.new profile_scan: "word_and_list"
      expect(config).to receive(:update!) do |args|
        expect(args.profile_scan).to eq("word_and_list")
      end
      UpdateConfigCommand.call(
        config,
        form,
        [],
        []
      )
    end

    it "update! scan_settings config attributes with a ScanSettingsForm" do
      form = Decidim::SpamSignal::Scans::WordSettingsForm.new(
        stop_list_words_csv: "foo,bar"
      ).with_context(handler_name: "word")
      expect(config).to receive(:update!) do |args|
        expect(args.scan_settings).to have_attribute("word")
      end
      UpdateConfigCommand.call(
        config,
        nil,
        [form],
        []
      )
    end

    it "updates only the ConfigForm if send both ConfigForm and ScanSettings" do
      settings_form = Decidim::SpamSignal::Scans::WordSettingsForm.new(
        stop_list_words_csv: "foo,bar"
      ).with_context(handler_name: "word")
      form = Decidim::SpamSignal::ConfigForm.new profile_scan: "word_and_list"
      expect(config).to receive(:update!) do |args|
        expect(args.profile_scan).to eq("word_and_list")
        expect(args.scan_settings).to be_empty
      end
      UpdateConfigCommand.call(
        config,
        form,
        [settings_form],
        []
      )
    end
  end
end
