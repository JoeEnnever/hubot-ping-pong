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

module.exports = ScoreKeeper
