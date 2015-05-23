#Evan Burchard (evanburchard.com)
#May, 2015

BIAS_VALUE = 4
SUCCESSFUL_MISSION = 8
FAILED_MISSION = 7
SUCCEEDED_AS_LEADER = 8
FAILED_AS_LEADER = 8
AVERAGE_REP_THRESHOLD = 6
LOWEST_REP_THRESHOLD = 1


NUMBER_OF_TRIALS = 1000


NOISY = false

class Game
  attr_accessor :missions, :players, :winner, :leader_number, :spy_strategy, :team_rejection_criteria
  def initialize(options = {spy_strategy: 'sneaky', team_rejection_criteria: 'low_rep_individual'})
    @missions = create_missions
    @players = create_players
    @winner = nil
    @leader_number = 0
    @spy_strategy = options[:spy_strategy] #sneaky (same as resistance) or random
    @team_rejection_criteria = options[:team_rejection_criteria]
  end

  def create_players
    players = []
    statuses = ["spy", "spy", "resistance", "resistance", "resistance"].shuffle
    statuses.length.times do |index|
      players.push(Player.new(index, statuses.pop, self) )
    end
    players
  end

  def create_missions
    missions = []
    [2, 3, 2, 3, 3].each_with_index do |team_size, index|
      missions.push(Mission.new(index, team_size, self))
    end
    missions
  end

  def print
    @missions.each do |mission|
      mission.print
    end
    puts "" if NOISY
    @players.each do |player|
      player.print
    end
    puts "" if NOISY
  end

  def next_mission
    @missions.find{|m| m.status == 'not_started'}
  end
  def failed_missions_count
    @missions.count{|m| m.status == 'failed'}
  end
  def successful_missions_count
    @missions.count{|m| m.status == 'successful'}
  end

  def not_started_missions_count
    @missions.count{|m| m.status == 'not_started'}
  end

  def status
    failed = failed_missions_count
    successful = successful_missions_count

    not_started = not_started_missions_count

    puts "#{not_started} missions left to go." if NOISY
    puts "#{failed} failed missions so far." if NOISY
    puts "#{successful} successful missions so far." if NOISY
    puts "\n" if NOISY
  end

  def start_mission
    next_mission.start
  end

  def check_for_winner
    if(failed_missions_count > 2)
      @winner = "spies win"
    end
    if(successful_missions_count > 2)
      @winner = "resistance wins"
    end
    @winner
  end
  def spies
    players.select{|p| p.status == "spy" }
  end

  def final_report
    puts "\nThe #{@winner} with #{not_started_missions_count} rounds to go!" if NOISY
    puts "#{spies[0].name} and #{spies[1].name} were spies\n\n" if NOISY
  end

  def short_report
    puts "#{@winner[0]}" if NOISY
  end

  def number_of_players
    @players.count
  end

  def new_leader
    @leader_number += 1
    @leader_number %= number_of_players
  end

  def leader
    @players.find{|p| p.number == @leader_number}
  end

  def average_reputation
    @players.inject{|sum, n| sum + n.reputation}/number_of_players
  end

end


class MissionTeam
  attr_accessor :mission, :game, :team, :mission_team_approved
  def initialize(mission, game)
    @game = game
    @mission = mission
    @team = choose_team
    @mission_team_approved = vote_on_team
  end

  def choose_team #DECISION
    puts "leader is Player #{game.leader_number}" if NOISY
    puts "team size is #{@mission.team_size}" if NOISY
    puts "leader is spy #{game.leader.is_spy?}" if NOISY

    team = [game.leader]
    temp_players_array = @game.players - [game.leader]

    sorted_temp_players_array = temp_players_array.sort_by{ |player| player.reputation}
    puts "Temp player array is #{sorted_temp_players_array}" if NOISY

    (@mission.team_size-1).times do

      if(game.spy_strategy = "random") #spies choose non-selves at random
        if(game.leader.status =="spy")
          team.push(sorted_temp_players_array.shuffle.pop) #do it at random
        else
          team.push(sorted_temp_players_array.pop) #take the most trusted
        end
      else #everyone chooses the most trusted
        team.push(sorted_temp_players_array.pop) #take the most trusted
      end
    end

    team
  end

  def vote_on_team #DECISION
    number_of_spies = @team.count{|m| m.status == "spy" }
    #puts "Team size is #{@team.count}" if NOISY
    doubt = 0
    game.players.each do |p|
      if p.is_spy? #the spies know who the spies are
        if(number_of_spies == 0 && @game.successful_missions_count > 1)
          doubt= doubt + 1
        elsif (@mission.vote_fail_count == 4 && @game.failed_missions_count > 1) #win if possible
          doubt = doubt + 1
        end
      elsif p.is_leader?
        doubt = doubt
      else
        if(@mission.vote_fail_count == 4) #always vote for a plan if it's critical
          doubt = doubt
        else
          doubt = doubt + 1 if (RejectionStrategy.execute({strategy: @game.team_rejection_criteria, number_of_spies: number_of_spies, team: @team, number_of_players: @game.number_of_players}))
        end
      end
    end
    !(doubt > 2)
  end
end

class RejectionStrategy
  def self.execute(options)
    if(options[:strategy]=='low_average_rep')
      average_rep = options[:team].inject(0){|sum, n| sum + n.reputation}/options[:number_of_players]
      average_rep > AVERAGE_REP_THRESHOLD
    elsif(options[:strategy]=='low_rep_individual')
      min_rep = options[:team].map(&:reputation).min
      min_rep > LOWEST_REP_THRESHOLD
    elsif(options[:strategy]=="omnipotent")
      options[:number_of_spies]>0 #if resistance knew who spies were
    end
  end
end

class Mission
  attr_accessor :number, :team_size, :status, :mission_team, :game, :vote_fail_count

  def initialize(number, team_size, game)
    @game = game
    @number = number
    @team_size = team_size
    @status = "not_started"
    @vote_fail_count = 0
  end

  def print
    puts "Mission #{@number}: \n team size: #{@team_size}\n status: #{@status}\n\n" if NOISY
  end

  def start
    puts "\nMission ##{@number}" if NOISY
    @status = "started"
    @mission_team = MissionTeam.new(self, @game)
    if(@mission_team.mission_team_approved)
      execute_mission
    else
      abort_mission
    end
  end

  def abort_mission
    @game.new_leader
    @vote_fail_count += 1
    puts "aborted the mission... that makes #{@vote_fail_count}" if NOISY
    if @vote_fail_count > 4
      @vote_fail_count = 0
      fail_mission
    else
      start
    end
  end

  def execute_mission
    end_mission(mission_should_fail?)
  end

  def mission_should_fail? #DECISION
    team = @mission_team.team
    number_of_spies = team.count{|m| m.status == "spy" }
    spies_have_cover = number_of_spies < team.size
    puts "number of spies is #{number_of_spies}" if NOISY
    if(number_of_spies > 0)
      if @game.failed_missions_count==2 #win if possible
        true
      elsif @game.successful_missions_count==2 #don't give them a win
        true
      elsif spies_have_cover #don't blow the cover
        true #might want to tweak this...
      else
        false
      end
    else
      false
    end
  end

  def end_mission(failure=true)
    puts "mission team was #{@mission_team.team}" if NOISY
    failure ? fail_mission : complete_mission
    @game.new_leader
  end

  def fail_mission
    @mission_team.team.each do |p|
      p.failed_mission
    end
    @game.leader.failed_as_leader

    puts "Mission ##{@number} failed!" if NOISY
    @status = "failed"
  end

  def complete_mission
    @mission_team.team.each do |p|
      p.successful_mission
    end
    @game.leader.succeeded_as_leader

    puts "Mission ##{@number} succeeded!" if NOISY
    @status = "successful"
  end

end

class Player
  attr_accessor :status, :number, :name, :reputation, :game
  def initialize(number, status, game)
    @status = status
    @number = number
    @name = "Player #{number}"
    @game = game
    @reputation = BIAS_VALUE
  end

  def print
    puts "Player #{@number}\n status: #{@status} " if NOISY
  end

  def is_spy?
    @status == "spy"
  end

  def is_leader?
    self == @game.leader
  end

  def successful_mission
    @reputation = ReputationCalculator.successful_mission(@reputation)
  end
  def failed_mission
    @reputation = ReputationCalculator.failed_mission(@reputation)
  end
  def succeeded_as_leader
    @reputation = ReputationCalculator.succeeded_as_leader(@reputation)
  end
  def failed_as_leader
    @reputation = ReputationCalculator.failed_as_leader(@reputation)
  end


end

class ReputationCalculator
  def self.successful_mission(rep)
    rep + SUCCESSFUL_MISSION
  end
  def self.failed_mission(rep)
    rep + FAILED_MISSION
  end
  def self.succeeded_as_leader(rep)
    rep + SUCCEEDED_AS_LEADER
  end
  def self.failed_as_leader(rep)
    rep + FAILED_AS_LEADER
  end
end


game_results = []
NUMBER_OF_TRIALS.times do
  game = Game.new

  5.times do
    game.start_mission
    break if game.check_for_winner
  end
  game.final_report
  game_results.push(game.winner[0])
end
resistance_wins = game_results.count{|e| e=='r'}
puts resistance_wins*100.0/NUMBER_OF_TRIALS
puts "BIAS_VALUE was #{BIAS_VALUE}"
puts "SUCCESSFUL_MISSION was #{SUCCESSFUL_MISSION}"
puts "FAILED_MISSION was #{FAILED_MISSION}"
puts "SUCCEEDED_AS_LEADER was #{SUCCEEDED_AS_LEADER}"
puts "FAILED_AS_LEADER was #{FAILED_AS_LEADER}"
puts "AVERAGE_REP_THRESHOLD was #{AVERAGE_REP_THRESHOLD}"
puts "LOWEST_REP_THRESHOLD was #{LOWEST_REP_THRESHOLD}"

