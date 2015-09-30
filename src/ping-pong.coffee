# Description:
#   Give or take away points. Keeps track and even prints out graphs.
#
# Dependencies:
#   "underscore": ">= 1.0.0"
#   "clark": "0.0.6"
#
# Configuration:
#
# Commands:
#   <name>++
#   <name>--
#   hubot score <name> [for <reason>]
#   hubot top <amount>
#   hubot bottom <amount>
#   hubot erase <user> [<reason>]
#   GET http://<url>/hubot/scores[?name=<name>][&direction=<top|botton>][&limit=<10>]
#
# Author:
#   ajacksified


_ = require('underscore')
clark = require('clark')
querystring = require('querystring')
ScoreKeeper = require('./scorekeeper')

module.exports = (robot) ->
  scoreKeeper = new ScoreKeeper(robot)

  # hubot pingpong record @joe 21 @keith 17
  robot.respond ///
    (?:ping(?:-)?pong record)
    # person 1
    (@\w+)
    # score 1
    (\d+)
    # person 2
    (@\w+)
    # score 2
    (\d+)
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
