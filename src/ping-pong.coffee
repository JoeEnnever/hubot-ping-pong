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
#   hubot ping-pong top - gives the top players by wins - losses
#
# Author:
#   JoeEnnever


_ = require('underscore')
ScoreKeeper = require('./scorekeeper')

module.exports = (robot) ->
  scoreKeeper = new ScoreKeeper(robot)

  # hubot pingpong record @joe 21 @keith 17
  robot.respond ///
    (?:ping(?:-)?pong)
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

    success = scoreKeeper.record(person1, score1, person2, score2)

    if success?
      message = "Congrats #{winner}, beating #{loser} #{high}-#{low}"
      msg.send message

  # hubot pingpong top
  robot.respond /ping(?:-)?pong top/i, (msg) ->
    results = scoreKeeper.matchRecords().sort (record1, record2) ->
      score1 = record1[1] - record1[2]
      score2 = record2[1] - record2[2]
      score1 - score2
    robot.logger.info(results)
    results = results[-5..].reverse()
    robot.logger.info(results)
    message = ("#{i + 1}. #{record[0]} - #{record[1]} Win(s) #{record[2]} Loss(es)" for record, i in results)
    robot.logger.info(message)
    msg.send message.join("\n")

