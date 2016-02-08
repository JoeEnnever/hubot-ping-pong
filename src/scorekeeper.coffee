# Description:
#   Helper class responsible for storing scores
#
# Dependencies:
#
# Configuration:
#
# Commands:
#
# Author:
#   ajacksified

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
      @users = ("@#{data.name}" for id, data of @robot.brain.users())

    @robot.brain.on "loaded", storageLoaded
    storageLoaded() # just in case storage was loaded before we got here

  record: (game, player1, score1, player2, score2) ->
    game = {}
    game[player1] = score1
    game[player2] = score2
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
    user in users

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

module.exports = ScoreKeeper
