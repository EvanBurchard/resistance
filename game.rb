#ASSUMPTIONS
#5 player game
#Spies play conservatively and hide most info
#Resistance makes decisions based on reputation of players DECISION

#TODO
#leader role
#reputations

class Evidence
  attr_accessor :name, :weight
  def initialize(name, weight)
    @name = name
    @weight = weight
  end
end

class Game
  attr_accessor :missions, :players, :winner, :leader_number
  def initialize
    @missions = create_missions
    @players = create_players
    @winner = nil
    @leader_number = 0
  end

  def create_players
    players = []
    statuses = ["spy", "spy", "resistance", "resistance", "resistance"].shuffle
    statuses.length.times do |index|
      players.push(Player.new(index, statuses.pop) )
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
    puts ""
    @players.each do |player|
      player.print
    end
    puts ""
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

    puts "leader is Player #{@leader_number}"
    puts "#{not_started} missions left to go."
    puts "#{failed} failed missions so far."
    puts "#{successful} successful missions so far."
    puts "\n"
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
    puts "\nThe #{@winner} with #{not_started_missions_count} rounds to go!"
    puts "#{spies[0].name} and #{spies[1].name} were spies\n\n"
  end

  def short_report
    puts "#{@winner[0]}"
  end

  def number_of_players
    @players.count
  end

  def new_leader
    @leader_number += 1
    @leader_number %= number_of_players
  end

end

class MissionTeam
  attr_accessor :mission, :leader, :game, :team, :mission_team_approved
  def initialize(mission, game)
    @game = game
    @mission = mission
    @team = choose_team
    @mission_team_approved = vote_on_team
  end
  def choose_team #DECISION
    puts "team size is #{@mission.team_size}"
    team = []
    temp_players_array = @game.players
    @mission.team_size.times do
      team.push(temp_players_array.shuffle.pop)
    end
    team
  end
  def vote_on_team #DECISION
    number_of_spies = @team.count{|m| m.status == "spy" }
    #puts "Team size is #{@team.count}"
    doubt = 0
    game.players.each do |p|
      if p.is_spy #the spies know who the spies are
        if(number_of_spies == 0 && @game.successful_missions_count > 1)
          doubt= doubt + 1
        elsif (@mission.vote_fail_count == 4 && @game.failed_missions_count > 1) #win if possible
          doubt= doubt + 1
        end
      else
        if(number_of_spies>0)
          doubt = doubt + 1
        end
      end
    end
    !(doubt > 2)
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
    puts "Mission #{@number}: \n team size: #{@team_size}\n status: #{@status}\n\n"
  end

  def start
    puts "Leader is player ##{game.leader_number}"
    puts "Mission ##{@number}"
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
    puts "aborted the mission... that makes #{@vote_fail_count}"
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
    puts "number of spies is #{number_of_spies}"
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
    failure ? fail_mission : complete_mission
    @game.new_leader
  end

  def fail_mission
    puts "Mission ##{@number} failed!"
    @status = "failed"
  end

  def complete_mission
    puts "Mission ##{@number} succeeded!"
    @status = "successful"
  end

end

class Player
  attr_accessor :status, :number, :name, :reputation, :evidence
  def initialize(number, status)
    @status = status
    @number = number
    @name = "Player #{number}"
    @reputation = 0
    @evidence = []
  end

  def print
    puts "Player #{@number}\n status: #{@status} "
  end
  def is_spy
    @status == "spy"
  end
  def evaluate(player)
    puts "evaluating player #{player.name}"
  end
end


games = []
20.times do |x|
  game = Game.new
  #game.print
  #game.status

  5.times do
    #game.status
    game.start_mission
    break if game.check_for_winner
  end
  game.final_report
  #game.short_report
  games.push(game)
end
