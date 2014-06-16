require 'spec_helper'

describe "Feed pages" do
  subject { page }
  let!(:time) { Chronic.parse("2015-01-05") }

  let!(:feed1) { FactoryGirl.create(:feed, last_paper_date: time) }
  let!(:feed2) { FactoryGirl.create(:feed, last_paper_date: time) }
  let!(:new_paper1) { FactoryGirl.create(:paper, feeds: [feed1], pubdate: time) }
  let!(:new_paper2) { FactoryGirl.create(:paper, feeds: [feed2], pubdate: time) }
  let!(:old_paper1) { FactoryGirl.create(:paper, feeds: [feed1], pubdate: time-1.day) }
  let!(:old_paper2) { FactoryGirl.create(:paper, feeds: [feed2], pubdate: time-1.day) }

  before do
    Search::Paper.index(new_paper1, new_paper2, old_paper1, old_paper2)
    Search.refresh
    Timecop.freeze(time)
  end

  after do
    Timecop.return
  end

  describe "Landing page" do
    before do
      visit root_path
    end

    it "shows today's papers" do
      expect(page).to have_content new_paper1.title
      expect(page).to have_content new_paper2.title
      expect(page).to_not have_content old_paper1.title
      expect(page).to_not have_content old_paper2.title
    end
  end

  describe "Home feed" do
    let(:user) { FactoryGirl.create(:user) }
    let(:prefs) { user.feed_preferences.where(feed_uid: nil).first_or_create }

    before do
      user.subscribe!(feed1)
      sign_in user
    end

    context "after not visiting for two days" do
      before do
        prefs.previous_last_visited = time-5.days
        prefs.last_visited = time-2.days
        prefs.save!
        visit root_path
      end

      it "shows the last two days of papers" do
        expect(page).to have_content new_paper1.title
        expect(page).to_not have_content new_paper2.title
        expect(page).to have_content old_paper1.title
        expect(page).to_not have_content old_paper2.title

        prefs.reload
        expect(prefs.previous_last_visited).to eq(time-2.days)
        expect(prefs.last_visited).to eq(time)
      end
    end

    context "visiting again in the same day" do
      before do
        prefs.previous_last_visited = time-2.days
        prefs.last_visited = time
        prefs.save!
        visit root_path
      end

      it "still shows the last two days of papers" do
        expect(page).to have_content new_paper1.title
        expect(page).to_not have_content new_paper2.title
        expect(page).to have_content old_paper1.title
        expect(page).to_not have_content old_paper2.title

        prefs.reload
        expect(prefs.previous_last_visited).to eq(time-2.days)
        expect(prefs.last_visited).to eq(time)
      end
    end
  end
end
