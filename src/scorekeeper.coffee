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
  constructor: (@robot) ->
    storageLoaded = =>
      @storage = @robot.brain.data.pingPong ||= {
        games: [] # Each game is { user1: score, user2: score }
        mmrs: {} # player -> MMR
      }
      @users = ("@#{data.name}" for id, data of @robot.brain.users())
      @robot.logger.info(@users)

      @robot.logger.info "Ping Pong Data Loaded: " + JSON.stringify(@storage, null, 2)
    @robot.brain.on "loaded", storageLoaded
    storageLoaded() # just in case storage was loaded before we got here

  record: (player1, score1, player2, score2) ->
    game = {}
    game[player1] = score1
    game[player2] = score2
    @storage.games.push(game)
    [winner, loser] =
      if score1 > score2
        [player1, player2]
      else
        [player2, player1]
    mmrChange = @calcMmrChange(winner, loser)
    @robot.brain.save()
    mmrChange

  userExists: (user) ->
    user in users

  mmrs: ->
    _.pick @storage.mmrs, (_value, key) =>
      @userExists(key)

  calcMmrChange: (winner, loser) ->
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
    @storage.mmrs[winner] = winnerMmr
    @storage.mmrs[loser] = loserMmr
    [winnerMmr, loserMmr]

  mmrScore: (a, b) ->
    exponent = (b - a) / 400.0
    1.0 / (1.0 + Math.pow(10, exponent))

  resetMmrs: ->
    @storage.mmrs = {}
    @robot.brain.save()

  matchRecords: ->
    # { joe => [wins, losses] }
    #
    #
    players = {
    }
    for game in @storage.games
      game_players = []
      for player, score of game
        continue unless @userExists(player)
        game_players.push([player, score])

      unless game_players.length == 2
        @robot.logger.info "Skipping recording bad game #{JSON.stringify(game, null, 2)}"
        continue
      [player1, score1] = game_players[0]
      [player2, score2] = game_players[1]
      [winner, loser] =
        if score1 > score2
          [player1, player2]
        else
          [player2, player1]
      players[winner] ||= [0, 0]
      players[winner][0]++

      players[loser] ||= [0, 0]
      players[loser][1]++

    ([player, wl[0], wl[1]] for player, wl of players)


module.exports = ScoreKeeper
