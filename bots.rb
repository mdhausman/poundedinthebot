require 'twitter_ebooks'
require 'twitter'
require 'yaml'

# This is an example bot definition with event handlers commented out
# You can define and instantiate as many bots as you like

class MyBot < Ebooks::Bot
  # Configuration here applies to all MyBots
  def configure
    log "Configuring MyBot"
    @config = YAML.load_file('config.yml')
    # Consumer details come from registering an app at https://dev.twitter.com/
    # Once you have consumer details, use "ebooks auth" for new access tokens
    self.consumer_key = @config['consumer_key'] # Your app consumer key
    self.consumer_secret = @config['consumer_secret'] # Your app consumer secret

    # Users to block instead of interacting with
    self.blacklist = ['tnietzschequote']

    # Range in seconds to randomize delay when bot.delay is called
    self.delay_range = 1..6
  end

  def on_startup
    sync_user = @config['user']
    debug = @config['debug']
    log "debug=#{debug}"
    archive = Ebooks::Archive.new("#{sync_user}")
    archive.sync
    model = Ebooks::Model.consume("corpus/#{sync_user}.json")
    model.save("model/#{sync_user}.model")
    
    #scheduler.every '24h' do
    scheduler.every (debug ? '30s' : '12h') do
      # Tweet something every 24 hours
      # See https://github.com/jmettraux/rufus-scheduler
      # tweet("hi")
      # pictweet("hi", "cuteselfie.jpg")
      statement = model.make_statement
      log statement
      unless debug then
        last_tweet = tweet(statement)
        log "<TWEET #{last_tweet.id}> Tweeted!"
        #every 12 hours we should generate this all again
        archive.sync
        model = Ebooks::Model.consume("corpus/#{sync_user}.json")
        model.save("model/#{sync_user}.model")
      end
    end
  end

  def on_message(dm)
    # Reply to a DM
    # reply(dm, "secret secrets")
    log "<DM> DM received from #{dm.sender.screen_name}: #{dm.text}"
    
  end

  def on_follow(user)
    # Follow a user back
    # follow(user.screen_name)
    log "<FOLLOW> #{user.screen_name} started following me!"
  end

  def on_mention(tweet)
    # Reply to a mention
    # reply(tweet, "oh hullo")
    log "<MENTION #{tweet.id}> #{tweet.sender.screen_name} mentioned me: #{tweet.text}"
  end

  def on_timeline(tweet)
    # Reply to a tweet in the bot's timeline
    # reply(tweet, "nice tweet")
    log "<RECEIVED #{tweet.id}> #{tweet.sender.screen_name} says: #{tweet.text}"
  end

  def on_favorite(user, tweet)
    # Follow user who just favorited bot's tweet
    # follow(user.screen_name)
    log "<FAVORITE #{tweet.id}> #{user.screen_name} favorited my tweet: #{tweet.text}"
  end

  def on_retweet(tweet)
    # Follow user who just retweeted bot's tweet
    # follow(tweet.user.screen_name)
    log "<RETWEET #{tweet.id}> #{tweet.sender.screen_name} mentioned me: #{tweet.text}"
  end
end

# Make a MyBot and attach it to an account
MyBot.new('poundedinthebot') do |bot|
  @config = YAML.load_file('config.yml')
  bot.access_token = @config['access_token'] # Token connecting the app to this account
  bot.access_token_secret = @config['access_token_secret'] # Secret connecting the app to this account
end
