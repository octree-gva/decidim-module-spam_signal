# frozen_string_literal: true

module Decidim
  module SpamSignal
    module Scans
      class AllowedTldsScanCommand < ScanHandler
        def self.form
          ::Decidim::SpamSignal::Scans::AllowedTldsForm
        end

        def call
          return broadcast(:ok) if allowed_tlds_csv.empty?
          return broadcast(:ok) if all_allowed?
          broadcast(:not_allowed_tlds_found)
        end

        def self.output_symbols
          [:not_allowed_tlds_found]
        end

        private

          def allowed_tlds_csv
            @allowed_tlds_csv ||= (
              config["allowed_tlds_csv"] || ""
            ).split(",").map(&:strip).filter {|tlds| !tlds.empty? }
          end

          def all_allowed?
            hosts.filter {|url| !allowed_tlds_csv.any? {|tld| url.include? tld } }.empty?
          end

          def hosts
            URI.extract(suspicious_content, ["http", "https", "", "mailto" ]).map do |uri|
              begin
                (scheme, subdomain, host ) = URI.split(uri)
                host || ""
              rescue URI::InvalidURIError
                ""
              end
            end

          end

          def regex(patterns)
            Regexp.union(patterns).source
          end
      end
    end
  end
end
