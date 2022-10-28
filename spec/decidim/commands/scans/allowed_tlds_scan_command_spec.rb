# frozen_string_literal: true

require "spec_helper"

describe Decidim::SpamSignal::Scans::AllowedTldsScanCommand::class do
  def scan_with_config(content, conf)
    Decidim::SpamSignal::Scans::AllowedTldsScanCommand.call(
      content,
      conf
    ) do
      on(:ok) { return :ok }
      on(:not_allowed_tlds_found) { return :not_allowed_tlds_found }
    end
  end

  context "with forbidden tlds=(.ch,.com)" do
    let(:allowed_tlds_config) { { "allowed_tlds_csv" => ".ch,.com" }}
    let(:config) do
      create(
        :spam_signal_config,
        comment_settings: {
          "scans" => {
            "allowed_tlds" => allowed_tlds_config
          }
        }
      )
    end
    def scan(content); scan_with_config(content, allowed_tlds_config); end
    context "is fine" do
      it("'There is no URL'") { expect(scan("There is no URL")).to be :ok }
      it("'this is not an url: crypto.finance is ok'") { expect(scan("this is not an url: crypto.finance is ok")).to be :ok }
      it("'http://good.url.com'") { expect(scan("http://good.url.com")).to be :ok }
      it("'http://www.good.url.ch'") { expect(scan("http://www.good.url.ch")).to be :ok }
      it("'http://infos.com.br'") { expect(scan("http://infos.com.br")).to be :ok }
    end
    context "found a forbidden domain" do
      it("'https://good.url.gov'") { expect(scan("http:s//good.url.gov")).to be :not_allowed_tlds_found }
      it("'Check https://crypto.finance'") { expect(scan("Check https://crypto.finance")).to be :not_allowed_tlds_found }
      it("'Check http://crypto.finance") { expect(scan("Check http://crypto.finance")).to be :not_allowed_tlds_found }
      it("'Click on [Google](https://escorts.ru) to read my blogpost'") { expect(scan("Click on [Google](https://escorts.ru) to read my blogpost")).to be :not_allowed_tlds_found }
      it("'Can't resist: https://a.subdomain.ru") { expect(scan("Can't resist: https://a.subdomain.ru")).to be :not_allowed_tlds_found }
    end
  end

  context "with empty forbidden tlds" do
    let(:allowed_tlds_config) { { "allowed_tlds_csv" => "" }}
    let(:config) do
      create(
        :spam_signal_config,
        comment_settings: {
          "scans" => {
            "allowed_tlds" => allowed_tlds_config
          }
        }
      )
    end
    def scan(content); scan_with_config(content, allowed_tlds_config); end
    context "is fine" do
      it("'call for dumb text'") { expect(scan("call for dumb text")).to be :ok }
      it("'http://good.url.com'") { expect(scan("http://good.url.com")).to be :ok }
      it("'Sexy https://ransomware.com'") { expect(scan("Sexy https://ransomware.com")).to be :ok }
      it("'https://hello.sexy.gg'") { expect(scan("https://hello.sexy.gg")).to be :ok }
      it("'https://ransomware.us let's talk") { expect(scan("https://ransomware.us let's talk")).to be :ok }
    end
  end

end
