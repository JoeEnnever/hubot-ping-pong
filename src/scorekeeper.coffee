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
class ScoreKeeper
  constructor: (@robot) ->
    storageLoaded = =>
      @storage = @robot.brain.data.pingPong ||= {
        games: []# Each game is { user1: score, user2: score }
      }

      @robot.logger.debug "Ping Pong Data Loaded: " + JSON.stringify(@storage, null, 2)
    @robot.brain.on "loaded", storageLoaded
    storageLoaded() # just in case storage was loaded before we got here

  record: (player1, score1, player2, score2) ->
    game = {}
    game[player1] = score1
    game[player2] = score2
    @storage.games.push(game)
    @robot.brain.save()
    true

  matchRecords: ->
    # { joe => [wins, losses] }
    #
    #
    players = {
    }
    for game in games
      game_players = []
      for player, score in game
        game_players.push([player, score])
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

    ([player, wl[0], wl[1]] for player, wl in players)


module.exports = ScoreKeeper
