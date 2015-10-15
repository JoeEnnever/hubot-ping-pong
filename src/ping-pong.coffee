# Description:
#   Ping pong
#
# Dependencies:
#   "underscore": ">= 1.0.0"
#   "clark": "0.0.6"
#
# Configuration:
#
# Commands:
#   hubot ping-pong record @player1 score2 @player2 score2 - record a match
#   hubot ping-pong top (n) - gives the n top players by wins - losses
#   hubot ping-pong mmrs (n) - gives the top n players by mmr
#
# Author:
#   JoeEnnever


_ = require('underscore')
ScoreKeeper = require('./scorekeeper')

module.exports = (robot) ->
  scoreKeeper = new ScoreKeeper(robot)
  pingpong = "(?:(:)?p[io]ng(?:[- ])?p[io]ng(:)?)"
  # hubot pingpong record @joe 21 @keith 17
  robot.respond ///
    #{pingpong}
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
    [__, person1, score1, person2, score2] = msg.match
    score1 = parseInt(score1, 10)
    score2 = parseInt(score2, 10)

    [winner, loser, high, low] = if score1 > score2
               [person1, person2, score1, score2]
             else
               [person2, person1, score2, score1]
    for person in [person1, person2]
      unless scoreKeeper.userExists(person)
        msg.send "Uh oh, I don't see anyone named #{person}. Game not recorded"
        return
    [winnerMmr, loserMmr] = scoreKeeper.record(person1, score1, person2, score2)

    msg.send "Congrats #{winner}, beating #{loser} #{high}-#{low}\n"
    msg.send "#{winner} MMR is now #{winnerMmr}"
    msg.send "#{loser} MMR is now #{loserMmr}"

  # hubot pingpong top
  robot.respond ///#{pingpong}\s*top(\s*\d+)?///i, (msg) ->
    [__, countStr] = msg.match
    count = parseInt(countStr) || 5
    results = scoreKeeper.matchRecords().sort (record1, record2) ->
      score1 = record1[1] - record1[2]
      score2 = record2[1] - record2[2]
      score1 - score2
    robot.logger.info(results)
    results = results[-count..].reverse()
    message = ("#{i + 1}. #{record[0]} - #{record[1]} Win(s) #{record[2]} Loss(es)" for record, i in results)
    msg.send message.join("\n")

  # hubot pingpong mmrs
  robot.respond ///#{pingpong}\s*mmrs(\s*\d+)?///i, (msg) ->
    [__, countStr] = msg.match
    count = parseInt(countStr) || 5
    mmrs = ([player, mmr] for player, mmr of scoreKeeper.mmrs())
    results = mmrs.sort (record1, record2) ->
      record1[1] - record2[1]
    results = results[-count..].reverse()
    message = ("#{i + 1}. #{record[0]} - #{record[1]} MMR" for record, i in results)
    msg.send message.join("\n")

  robot.respond ///#{pingpong}\s*who\s*should\s*I\s*play///i, (msg) ->
    user = msg.message.user.name
    user = "@#{user}" unless user[0] == '@'
    mmr = scoreKeeper.mmrs()[user]
    unless mmr
      msg.send "Sorry, I don't have an MMR for you, #{user}"
      msg.send "Go play some ping-pong!"
      return

    nearby = []
    closetBelow = 0
    closestAbove = 9999999
    above = below = null
    for otherUser, otherMmr of scoreKeeper.mmrs()
      continue if otherUser == user
      if otherMmr > closetBelow && otherMmr <= mmr
        closetBelow = otherMmr
        below = otherUser
      if otherMmr < closestAbove && otherMmr >= mmr
        closestAbove = otherMmr
        above = otherUser

    nearby.push(below) if below
    nearby.push(above) if above
    msg.send "Why don't you play #{nearby.join(" or ")}?"

  robot.respond ///#{pingpong}\s*reset\s*mmrs///i, (msg) ->
    user = msg.message.user.name
    user = "@#{user}" unless user[0] == '@'
    admin = process.env.HUBOT_PING_PONG_ADMIN_USER
    unless user == admin
      msg.send "Sorry, only #{admin} can reset the leaderboard"
      return
    scoreKeeper.resetMmrs()
    msg.send "MMR leaderboard reset"
