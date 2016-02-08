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
ScoreKeeper = require('./scorekeeper')

module.exports = (robot) ->
  games = process.env.HUBOT_MMR_GAMES.split(',')
  scoreKeeper = new ScoreKeeper(robot, games)
  pingpong = "(?:(?::)?p[io]ng(?:[- ])?p[io]ng(?::)?)"
  gamesRegex = "(#{games.join("|")})"
  games = games.map (game) ->
    if game.match(pingpong)
      'pingPong'
    else
      game
  # hubot pingpong record @joe 21 @keith 17
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
    [game, person1, score1, person2, score2] = msg.match
    score1 = parseInt(score1, 10)
    score2 = parseInt(score2, 10)
    game = game.toLowerCase()
    unless game in games
      msg.send "I don't know game #{game}, just #{games}"
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
    [game, countStr] = msg.match
    game = game.toLowerCase()
    unless game in games
      msg.send "I don't know game #{game}, just #{games}"
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
