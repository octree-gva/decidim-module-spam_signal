# frozen_string_literal: true

require "spec_helper"

describe Decidim::SpamSignal::Scans::ForbiddenTldsScanCommand::class do
  def scan_with_config(content, conf)
    Decidim::SpamSignal::Scans::ForbiddenTldsScanCommand.call(
      content,
      conf
    ) do
      on(:ok) { return :ok }
      on(:forbidden_tlds_found) { return :forbidden_tlds_found }
    end
  end

  context "with forbidden tlds=(.finance,.fin.br)" do
    let(:forbidden_tlds_config) { { "forbidden_tlds_csv" => ".finance,.fin.br" }}
    let(:config) do
      create(
        :spam_signal_config,
        comment_settings: {
          "scans" => {
            "forbidden_tlds" => forbidden_tlds_config
          }
        }
      )
    end
    def scan(content); scan_with_config(content, forbidden_tlds_config); end
    context "is fine" do
      it("'There is no URL'") { expect(scan("There is no URL")).to be :ok }
      it("'this is not an url: crypto.finance is ok'") { expect(scan("this is not an url: crypto.finance is ok")).to be :ok }
      it("'http://good.url.com'") { expect(scan("http://good.url.com")).to be :ok }
      it("'http://participa.social.br'") { expect(scan("http://participa.social.br")).to be :ok }
      it("'http://infos.com.br'") { expect(scan("http://infos.com.br")).to be :ok }
    end
    context "found a forbidden domain" do
      it("'Check https://crypto.finance'") { expect(scan("Check https://crypto.finance")).to be :forbidden_tlds_found }
      it("'Check http://crypto.finance") { expect(scan("Check http://crypto.finance")).to be :forbidden_tlds_found }
      it("'Click on [Google](https://escorts.fin.br) to read my blogpost'") { expect(scan("Click on [Google](https://escorts.fin.br) to read my blogpost")).to be :forbidden_tlds_found }
      it("'Can't resist: https://a.subdomain.fin.br") { expect(scan("Can't resist: https://a.subdomain.fin.br")).to be :forbidden_tlds_found }
    end
  end

  context "with empty forbidden tlds" do
    let(:forbidden_tlds_config) { { "forbidden_tlds_csv" => "" }}
    let(:config) do
      create(
        :spam_signal_config,
        comment_settings: {
          "scans" => {
            "forbidden_tlds" => forbidden_tlds_config
          }
        }
      )
    end
    def scan(content); scan_with_config(content, forbidden_tlds_config); end
    context "is fine" do
      it("'call for dumb text'") { expect(scan("call for dumb text")).to be :ok }
      it("'http://good.url.com'") { expect(scan("http://good.url.com")).to be :ok }
      it("'Sexy https://ransomware.com'") { expect(scan("Sexy https://ransomware.com")).to be :ok }
      it("'https://hello.sexy.gg'") { expect(scan("https://hello.sexy.gg")).to be :ok }
      it("'https://ransomware.com let's talk") { expect(scan("https://ransomware.com let's talk")).to be :ok }
    end
  end

end
