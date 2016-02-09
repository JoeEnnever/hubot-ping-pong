# Description:
#   Ping pong
#
# Dependencies:
#   "underscore": ">= 1.0.0"
#   "clark": "0.0.6"
#
# Configuration:
#   HUBOT_MMR_GAMES
#
# Commands:
#   hubot mmr (game) record @player1 score2 @player2 score2 - record a match
#   hubot mmr (game) top (n) - gives the n top players by mmr
#
# Author:
#   JoeEnnever


_ = require('underscore')

class ScoreKeeper
  constructor: (@robot, @games) ->
    storageLoaded = =>
      @storage = @robot.brain.data
      for game in @games
        @storage[game] ||= {
          games: [] # Each game is { user1: score, user2: score }
          mmrs: {} # player -> MMR
        }
      console.log(JSON.stringify(@storage))
      @users = ("@#{data.name}" for id, data of @robot.brain.users())

    @robot.brain.on "loaded", storageLoaded
    storageLoaded() # just in case storage was loaded before we got here

  record: (game, player1, score1, player2, score2) ->
    game = {}
    game[player1] = score1
    game[player2] = score2
    console.log(JSON.stringify(game))
    console.log(JSON.stringify(@storage[game]))
    @storage[game].games.push(game)
    [winner, loser] =
      if score1 > score2
        [player1, player2]
      else
        [player2, player1]
    mmrChange = @calcMmrChange(game, winner, loser)
    @robot.brain.save()
    mmrChange

  userExists: (user) ->
    user in @users

  mmrs: (game) ->
    _.pick @storage[game].mmrs, (_value, key) =>
      @userExists(key)

  calcMmrChange: (game, winner, loser) ->
    @storage.mmrs ||= {}
    @storage.mmrs[winner] ||= 2000
    @storage.mmrs[loser] ||= 2000

    winnerMmr = @storage.mmrs[winner]
    loserMmr = @storage.mmrs[loser]

    winnerExpectedScore = @mmrScore(winnerMmr, loserMmr)
    @robot.logger.info("Winner was #{winnerMmr}")
    @robot.logger.info("Loser was #{loserMmr}")
    pointAdjustment = (1 - winnerExpectedScore)
    winnerMmr += 50 * pointAdjustment
    loserMmr -= 50 * pointAdjustment
    winnerMmr = parseInt(winnerMmr, 10)
    loserMmr = parseInt(loserMmr, 10)
    @robot.logger.info("Winner is #{winnerMmr}")
    @robot.logger.info("Loser is #{loserMmr}")
    @storage[game].mmrs[winner] = winnerMmr
    @storage[game].mmrs[loser] = loserMmr
    [winnerMmr, loserMmr]

  mmrScore: (a, b) ->
    exponent = (b - a) / 400.0
    1.0 / (1.0 + Math.pow(10, exponent))

  reset: (game) ->
    @storage[game].mmrs = {}
    @storage[game].games = []
    @robot.brain.save()

module.exports = (robot) ->
  games = process.env.HUBOT_MMR_GAMES.split(',')
  scoreKeeper = new ScoreKeeper(robot, games)
  gamesRegex = "(#{games.join("|")})"

  robot.respond ///
    (?:mmr)
    \s*
    #{gamesRegex}
    \s*
    (?:record)
    \s*
    # person 1
    (@\w+)
    \s*
    # score 1
    (\d+)
    \s*
    # person 2
    (@\w+)
    \s*
    # score 2
    (\d+)
    \s*
    $ # eol
  ///i, (msg) ->
    [__, game, person1, score1, person2, score2] = msg.match
    score1 = parseInt(score1, 10)
    score2 = parseInt(score2, 10)
    game = game.toLowerCase()
    unless game in games
      msg.send "I don't know #{game}, just #{games}"
      return
    [winner, loser, high, low] = if score1 > score2
               [person1, person2, score1, score2]
             else
               [person2, person1, score2, score1]
    if person1 == person2
      msg.send "Damnit Todd"
      return
    for person in [person1, person2]
      unless scoreKeeper.userExists(person)
        msg.send "Uh oh, I don't see anyone named #{person}. Game not recorded"
        return
    [winnerMmr, loserMmr] = scoreKeeper.record(game, person1, score1, person2, score2)

    msg.send "Congrats #{winner}, beating #{loser} #{high}-#{low}\n"
    msg.send "#{winner} MMR is now #{winnerMmr}"
    msg.send "#{loser} MMR is now #{loserMmr}"

  # hubot pingpong mmrs
  robot.respond ///mmr(?:s)?\s*#{gamesRegex}\s*top(\s*\d+)?///i, (msg) ->
    [__, game, countStr] = msg.match
    game = game.toLowerCase()
    unless game in games
      msg.send "I don't know #{game}, just #{games}"
      return
    count = parseInt(countStr) || 5
    mmrs = ([player, mmr] for player, mmr of scoreKeeper.mmrs(game))
    results = mmrs.sort (record1, record2) ->
      record1[1] - record2[1]
    results = results[-count..].reverse()
    message = ("#{i + 1}. #{record[0][1..-1]} - #{record[1]} MMR" for record, i in results)
    msg.send message.join("\n")

  # robot.respond ///#{pingpong}\s*reset\s*mmrs///i, (msg) ->
  #   user = msg.message.user.name
  #   user = "@#{user}" unless user[0] == '@'
  #   admin = process.env.HUBOT_PING_PONG_ADMIN_USER
  #   unless user == admin
  #     msg.send "Sorry, only #{admin} can reset the leaderboard"
  #     return
  #   scoreKeeper.reset()
  #   msg.send "MMR leaderboard reset"
