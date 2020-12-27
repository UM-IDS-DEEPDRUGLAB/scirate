require 'spec_helper'

describe "Admin tools" do
  describe "Comment moderation" do
    before do
      @moderator = FactoryGirl.create(:user, account_status: User::STATUS_MODERATOR)
      @paper = FactoryGirl.create(:paper_with_comments_and_categories)
      @comment = @paper.comments.where(deleted: false).first
      @deleted_comment = @paper.comments.where(deleted: true).first
      sign_in @moderator
    end

    it "shows moderation actions and deleted comments" do
      visit paper_path(@paper)

      expect(page).to have_content('moderator:')
      expect(page).to have_content('edit')
      expect(page).to have_content('delete')

      expect(page).to have_content("this is a deleted comment")
    end

    it "lets moderators edit comments" do
      post edit_comment_path(@comment), params: { content: "wubbles" }, xhr: true
      expect(response).to be_successful
      expect(@comment.reload.content).to eq("wubbles")
    end

    it "lets moderators delete comments" do
      expect do
        post delete_comment_path(@comment), xhr: true
        expect(flash[:comment][:status]).to eq('success')
        @paper.reload
      end.to change(@paper, :comments_count).by(-1)
    end

    it "lets moderators restore comments" do
      expect do
        post restore_comment_path(@deleted_comment), xhr: true
        expect(flash[:comment][:status]).to eq('success')
        @paper.reload
      end.to change(@paper, :comments_count).by(1)
    end
  end

  # TODO: rewrite this spec, this spec is not correctly written
  # describe "Editing users" do
  #   before do
  #     @moderator = FactoryGirl.create(:user, account_status: User::STATUS_MODERATOR)
  #     @admin = FactoryGirl.create(:user, account_status: User::STATUS_ADMIN)
  #     @comment = FactoryGirl.create(:comment)
  #     @user = @comment.user
  #   end

  #   it "doesn't let moderators edit users" do
  #     sign_in @moderator

  #     xhr :post, admin_update_user_path(@user)
  #     response.should be_redirect

  #     visit edit_admin_user_path(@user)
  #     current_path.should == root_path
  #   end

  #   it "lets an admin update a user" do
  #     sign_in @admin
  #     visit "/admin/users/#{@user.id}/edit"
  #     page.should have_content("admin: editing #{@user.username}")

  #     new_username = "bobbles"
  #     new_name = "Mr. Bobbles"
  #     new_email = "bobbles@example.com"
  #     new_status = User::STATUS_SPAM

  #     fill_in "Username", with: new_username
  #     fill_in "Name", with: new_name
  #     fill_in "Email", with: new_email
  #     select new_status, from: "Account Status"
  #     click_button "Save changes"

  #     @user.reload
  #     @user.username.should == new_username
  #     @user.fullname.should == new_name
  #     @user.email.should == new_email
  #     @user.account_status.should == new_status

  #     # Ensure marking as spam hides comments
  #     @user.comments.where(hidden: true).count.should == 1
  #   end
  # end
end
