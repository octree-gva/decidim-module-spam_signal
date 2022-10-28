# frozen_string_literal: true

module Decidim
  module SpamSignal
    module Cops
      class LockCopCommand < CopHandler
        def self.form
          ::Decidim::SpamSignal::Cops::LockSettingsForm
        end

        def call
          errors.add(
            :base,
            I18n.t("errors.spam",
              scope: "decidim.spam_signal",
              default: "this looks like spam."
            )
          )
          unless suspicious_user.access_locked?
            hide_comment! if config["hide_comments_enabled"]
            sinalize! if config["sinalize_user_enabled"]
            lock!
          end
        end

        private
          def hide_comment!
            suspicious_comments = Decidim::Comments::Comment.where(author: suspicious_user)
            suspicious_comments.each do |spam|
              moderation = Decidim::Moderation.find_or_create_by!(
                reportable: spam,
                participatory_space: spam.participatory_space
              )
              moderation.update(reported_content: spam.body[admin_reporter.locale]) if !moderation.reported_content && spam.body[admin_reporter.locale]
              Decidim::Report.create!(
                moderation: moderation.reload,
                user: admin_reporter,
                locale: admin_reporter.locale,
                reason: "spam",
                details: I18n.t("decidim.spam_signal.spam_signal_justification", default: "Automatic Spam Analysis fire an alert about this content")
              )
              moderation.update!(report_count: moderation.report_count + 1, hidden_at: Time.current)
            end
          end

          def sinalize!
            moderation = Decidim::UserModeration.find_or_create_by!(user: suspicious_user)
            Decidim::UserReport.find_or_create_by!(moderation: moderation)  do |report|
              report.moderation = moderation
              report.user = admin_reporter
              report.reason = "spam"
              report.details = I18n.t("decidim.spam_signal.spam_signal_justification")
            end
          end

          def lock!
            suspicious_user.lock_access!(
              send_instructions: true
            )
            suspicious_user.save!(validate: false)
          end
      end
    end
  end
end
