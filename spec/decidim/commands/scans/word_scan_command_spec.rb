# frozen_string_literal: true

require "spec_helper"

describe Decidim::SpamSignal::Scans::WordScanCommand::class do
  def scan_with_config(content, conf)
    Decidim::SpamSignal::Scans::WordScanCommand.call(
      content,
      conf
    ) do
      on(:ok) { return :ok }
      on(:word_found) { return :word_found }
    end
  end

  context "with dictionnary=(sexy,call girl,Let's talk)" do
    let(:word_config) { { "stop_list_words_csv" => "sexy,call girl,Let's talk" }}
    let(:config) do
      create(
        :spam_signal_config,
        comment_settings: {
          "scans" => {
            "word" => word_config
          }
        }
      )
    end
    def scan(content); scan_with_config(content, word_config); end
    context "is fine" do
      it("'call for dumb text'") { expect(scan("call for dumb text")).to be :ok }
      it("'http://good.url.com'") { expect(scan("http://good.url.com")).to be :ok }
    end
    context "found a word" do
      it("'https://hello.sexy.gg'") { expect(scan("https://hello.sexy.gg")).to be :word_found }
      it("'Sexy https://ransomware.com'") { expect(scan("Sexy https://ransomware.com")).to be :word_found }
      it("'https://ransomware.com let's talk") { expect(scan("https://ransomware.com let's talk")).to be :word_found }
    end
  end

  context "with empty dictionnary" do
    let(:word_config) { { "stop_list_words_csv" => "" }}
    let(:config) do
      create(
        :spam_signal_config,
        comment_settings: {
          "scans" => {
            "word" => word_config
          }
        }
      )
    end
    def scan(content); scan_with_config(content, word_config); end
    context "is fine" do
      it("'call for dumb text'") { expect(scan("call for dumb text")).to be :ok }
      it("'http://good.url.com'") { expect(scan("http://good.url.com")).to be :ok }
      it("'Sexy https://ransomware.com'") { expect(scan("Sexy https://ransomware.com")).to be :ok }
      it("'https://hello.sexy.gg'") { expect(scan("https://hello.sexy.gg")).to be :ok }
      it("'https://ransomware.com let's talk") { expect(scan("https://ransomware.com let's talk")).to be :ok }
    end
  end

end
