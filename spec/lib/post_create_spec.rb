require 'spec_helper'

describe "Post Created" do
  before :all do
    @user = create :User
    @post = create :Post
    @league_id = rand(20)
    @user_daily = create :UserDaily, { user: @user.id, day: Time.now.strftime("%d"), month: Time.now.strftime("%m"), year: Time.now.strftime("%Y") }
    @user_weekly = create :UserWeekly, { user: @user.id, week: Time.now.strftime("%W"), year: Time.now.strftime("%Y") }
    @league_counters = create :LeagueCounters, { id: @league_id }
    @league_writers = create :LeagueWriters, { id: @league_id }
  end

  before :all do
    open("http://#{HOST}/post_create?user=#{@user.id}&post=#{@post.id}&league=#{@league_id}&league_count=true&writers_count=true")
  end

  it "should increase the user's num of posts created by 1" do
    @user.data["post_create"].to_i.should eq @user.initial_data["post_create"].to_i + 1
  end

  it "should increase the user's weekly num of posts created" do
    @user_weekly.data["post_create"].to_i.should eq @user_weekly.initial_data["post_create"].to_i + 1
  end

  describe "UserDaily" do
    it "should increase the daily logins of the user by one" do
      @user_daily.data["post_create"].to_i.should eq @user_daily.initial_data["post_create"].to_i + 1
    end

    it "should set a TTL for the objects" do
      $redis.ttl(@user_daily.key).should > 0
    end
  end

  describe "LeagueCounters" do
    describe "posts" do
      it "should increase the league posts count if league_count is not false" do
        @league_counters.data["posts"].to_i.should eq @league_counters.initial_data["posts"].to_i + 1
      end

      it "should not increase the league posts count if league_count is false" do
        open("http://#{HOST}/post_create?user=#{@user.id}&post=#{@post.id}&league=#{@league_id}&league_count=0&writers_count=true")  
        @league_counters.data["posts"].to_i.should eq @league_counters.initial_data["posts"].to_i + 1
      end
    end

    describe "writers" do
      before :all do
        @current_data = @league_counters.data
      end

      it "should not increase the number of writers for the league if its not a new writer" do
        open("http://#{HOST}/post_create?user=#{@user.id.to_i}&post=#{@post.id}&league=#{@league_id}&league_count=true&writers_count=true")
        @league_counters.data["writers"].to_i.should eq @current_data["writers"].to_i     
      end

      it "should not increase the number of writers for the league if its a new writer but writers_count is false" do
        open("http://#{HOST}/post_create?user=#{@user.id.to_i + 1}&post=#{@post.id}&league=#{@league_id}&league_count=true&writers_count=false")
        @league_counters.data["writers"].to_i.should eq @current_data["writers"].to_i    
      end

      it "should increase the number of writers for the league if its a new writer" do
        open("http://#{HOST}/post_create?user=#{@user.id.to_i + 1}&post=#{@post.id}&league=#{@league_id}&league_count=true&writers_count=true")
        @league_counters.data["writers"].to_i.should eq @current_data["writers"].to_i + 1
      end
    end
  end

  describe "LeagueWriters" do
    it "should add 1 to the user who created the post" do
      @league_writers.set["user_#{@user.id}"].to_i.should == @league_writers.initial_set["user_#{@user.id}"].to_i + 3  # greater by 3 because of previous spec who does another call
    end

    it "should not add 1 to the user who created the post if writers_count is false" do
      open("http://#{HOST}/post_create?user=#{@user.id}&post=#{@post.id}&league=#{@league_id}&league_count=true&writers_count=false")  
      @league_writers.set["user_#{@user.id}"].to_i.should == @league_writers.initial_set["user_#{@user.id}"].to_i + 3  # greater by 3 because of previous spec who does another call
    end
  end
end
