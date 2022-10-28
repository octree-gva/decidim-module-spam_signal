# frozen_string_literal: true

require "spec_helper"
module Decidim::SpamSignal::Cops
  describe LockCopCommand::class do
    let(:organization) { create :organization }
    let(:spam_cop) { Decidim::SpamSignal::CopBot.get(organization) }
    let(:spammer) { create(:user, organization: organization) }
    let(:user) { create(:user, organization: organization) }
    let(:participatory_process) { create(:participatory_process, organization: organization) }
    let(:component) { create(:component, participatory_space: participatory_process) }
    let(:dummy_resource) { create(:dummy_resource, component: component, author: user) }
    let(:target_content) { dummy_resource }
    let!(:comment) { create(:comment, commentable: target_content, author: spammer) }
    let(:config) { {"sinalize_user_enabled" => false, "hide_comments_enabled" => false} }
    let(:spam_content) { "spam and ham" }


    context "LockCopCommand.call with sinalize_user_enabled=false, hide_comments_enabled=false options" do
      let(:config) { {"sinalize_user_enabled" => false, "hide_comments_enabled" => false} }
      it "set the handler_name to lock" do
        expect(LockCopCommand.handler_name).to eq("lock")
      end

      it "locks the user" do
        expect do
          LockCopCommand.call(comment.errors, spammer, config, spam_content, spam_cop)
        end.to change { spammer.reload.access_locked? }.from(false).to(true)
      end

      it "does not sinalize the user" do
        expect do
          LockCopCommand.call(comment.errors, spammer, config, spam_content, spam_cop)
        end.not_to change { Decidim::UserModeration.where(user: spammer).count }
      end

      it "does not hide user's comments" do
        LockCopCommand.call(comment.errors, spammer, config, spam_content, spam_cop)
        expect(comment.reload).not_to be_hidden
      end
      
      it "does add a :base error on resource" do
        expect(comment.errors).to receive(:add)
        LockCopCommand.call(comment.errors, spammer, config, spam_content, spam_cop)
      end
    end

    context "LockCopCommand.call with sinalize_user_enabled=true, hide_comments_enabled=false options" do
      let(:config) { {"sinalize_user_enabled" => true, "hide_comments_enabled" => false} }
      it "locks the user" do
        expect do
          LockCopCommand.call(comment.errors, spammer, config, spam_content, spam_cop)
        end.to change { spammer.reload.access_locked? }.from(false).to(true)
      end

      it "does sinalize the user" do
        expect do
          LockCopCommand.call(comment.errors, spammer, config, spam_content, spam_cop)
        end.to change { Decidim::UserModeration.where(user: spammer).count }.by(1)
      end

      it "does not hide user's comments" do
        LockCopCommand.call(comment.errors, spammer, config, spam_content, spam_cop)
        expect(comment.reload).not_to be_hidden
      end
    end
    context "LockCopCommand.call with sinalize_user_enabled=false, hide_comments_enabled=true options" do
      let(:config) { {"sinalize_user_enabled" => false, "hide_comments_enabled" => true} }
      it "locks the user" do
        expect do
          LockCopCommand.call(comment.errors, spammer, config, spam_content, spam_cop)
        end.to change { spammer.reload.access_locked? }.from(false).to(true)
      end

      it "does not sinalize the user" do
        expect do
          LockCopCommand.call(comment.errors, spammer, config, spam_content, spam_cop)
        end.not_to change { Decidim::UserModeration.where(user: spammer).count }
      end

      it "does hide user's comments" do
        previous_comment = create(:comment, commentable: target_content, author: spammer)
        LockCopCommand.call(comment.errors, spammer, config, spam_content, spam_cop)
        expect(comment.reload).to be_hidden
        expect(previous_comment.reload).to be_hidden
      end
    end
  end
end
