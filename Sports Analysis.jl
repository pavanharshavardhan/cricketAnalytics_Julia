using DataFrames, XLSX, Statistics

# Read the dataset of cricket players and their ICC batting points from "batsmen_new.xlsx"
xlsx_file = "batsmen_new.xlsx"
df = DataFrame(XLSX.readtable(xlsx_file, "Sheet1"))

# Drop all the rows with NaN scores
df = dropmissing(df)

# Sort the dataset by batting points in descending order
sort!(df, :ICC_Batting_Points, rev=true)

# Calculate the percentile rank for each player
df[!, :Percentile_Rank] = [searchsortedlast(sort(df[!, :ICC_Batting_Points]), x) / nrow(df) * 100 for x in df[!, :ICC_Batting_Points]]
df

# Set the percentile score of the lowest-ranked player to 1
min_rank = minimum(df[!, :Percentile_Rank])
df[!, :Percentile_Score] .= @. 100 - ((df[!, :Percentile_Rank] - min_rank) / (100 - min_rank))
df

# Define a dictionary mapping short country names to full country names
country_names = Dict(
    "IND" => "India",
    "PAK" => "Pakistan",
    "AFG" => "Afghanistan",
    "SL" => "Sri Lanka",
    "BAN" => "Bangladesh",
    "NZ" => "New Zealand",
    "AUS" => "Australia",
    "SA" => "South Africa",
    "ENG" => "England",
    "NED" => "Netherlands",
    "WI" => "West Indies",
    "ZIM" => "Zimbabwe",
    "IRE" => "Ireland",
    "SCO" => "Scotland",
    "NAM" => "Namibia"
)

# Replace the short country names with full country names in the "Player_Nation" column
df[!, :Player_Nation] .= [country_names[name] for name in df[!, :Player_Nation]]
df


# Display the first 5 rows of the DataFrame
first(df, 5)

batsman = df[!, :Player_Name]
batsman_country = df[!, :Player_Nation]
batsman_rank = df[!, :Percentile_Rank]


# Read the dataset of cricket players and their ICC bowling points from "bowlers_new.xlsx"
xlsx_file = "bowlers_new.xlsx"
df_bowlers = DataFrame(XLSX.readtable(xlsx_file, "Sheet1"))

# Drop all the rows with NaN scores
df_bowlers = dropmissing(df_bowlers)

# Sort the dataset by bowling points in descending order
sort!(df_bowlers, :ICC_Bowling_Points, rev=true)

# Calculate the percentile rank for each player
df_bowlers[!, :Percentile_Rank] .= [searchsortedlast(sort(df_bowlers[!, :ICC_Bowling_Points]), x) / nrow(df_bowlers) * 100 for x in df_bowlers[!, :ICC_Bowling_Points]]
df_bowlers

# Set the percentile score of the lowest-ranked player to 1
min_rank = minimum(df_bowlers[!, :Percentile_Rank])
df_bowlers[!, :Percentile_Score] .= @. 100 - ((df_bowlers[!, :Percentile_Rank] - min_rank) / (100 - min_rank))
df_bowlers

#converting to list
bowler = df_bowlers[!, :Bowler_Name]
bowler_country = df_bowlers[!, :Player_Nation]
bowler_rank = df_bowlers[!, :Percentile_Rank]

df = DataFrame(Player_Name = batsman, Player_Nation = batsman_country, PercentileRank = batsman_rank)

# Sort the DataFrame by the "Player_Nation" column
sort!(df, :Player_Nation)

df2 = DataFrame(Player_Name = bowler, Player_Nation = bowler_country, Percentile_Rank = bowler_rank)

# Sort the DataFrame by the "Player_Nation" column
sort!(df2, :Player_Nation)

# Define the list of countries to keep
countries_to_keep = ["India", "Pakistan", "Afghanistan", "Sri Lanka", "Bangladesh", "New Zealand", "Australia", "South Africa", "England", "Netherlands"]

# Filter the DataFrame to only include rows from the countries in the list
df_filtered_bowl = filter(row -> in(row.Player_Nation, countries_to_keep), df2)

# Filter the DataFrame to only include rows from the countries in the list
df_filtered_bat = filter(row -> in(row.Player_Nation, countries_to_keep), df)

# Define the dictionary to store the results
team_dict_bat = Dict{String, Vector{Float64}}()

# Iterate over the DataFrame and add each team to the dictionary
for row in eachrow(df_filtered_bat)
    team = row.Player_Nation
    percentile_rank = row.PercentileRank

    # If the team is not already in the dictionary, add it
    if haskey(team_dict, team)
        team_dict_bat[team][1] += 1
        team_dict_bat[team][2] += percentile_rank
    else
        team_dict_bat[team] = [1, percentile_rank]
    end
end

# Print the dictionary. 
# Key is the team, value is a list containing no of players of the team in dataset and sum of their cumulative percentile scores 
team_dict_bat

# Define the dictionary to store the team scores
team_scores = Dict{String, Float64}()

# Iterate over the DataFrame and calculate the score for each team
for row in eachrow(df_filtered_bat)
    team = row.Player_Nation
    percentile_rank = row.PercentileRank

    # If the team is not already in the dictionary, add it.
    if !haskey(team_scores, team)
        team_scores_bat[team] = 0.0
    end

    # Add the percentile rank of the player to the team score.
    team_scores_bat[team] += percentile_rank

    # Get the number of players from the team in the DataFrame.
    num_players = sum(df_filtered_bat.Player_Nation .== team)

    # If there are fewer than 7 players from the team in the DataFrame, calculate the score for missing players.
    if num_players < 7
        # Get the lowest score of players from that team.
        lowest_score = minimum(df_filtered_bat[df_filtered_bat.Player_Nation .== team, :PercentileRank])

        # Calculate the score for the missing players.
        missing_player_score = (lowest_score / 3.0) * (7 - num_players)

        # Add the score for the missing players to the team score.
        team_scores_bat[team] += missing_player_score
    end
end

# Create arrays to store the results
teams = String[]
batting_score = Float64[]

# Print the results and store them in arrays
for (team, score) in team_scores
    println("$team : $score")
    push!(teams, team)
    push!(batting_score, score)
end

sorted_team_scores_bat = sort(collect(team_scores), by=x->x[2], rev=true)

# Print the results
for (team, score) in sorted_team_scores_bat
    println("$team : $score")
end

# Define the dictionary to store the results
team_dict_bowl = Dict{String, Vector{Int}}()

# Iterate over the DataFrame and add each team to the dictionary
for row in eachrow(df_filtered_bowl)
    team = row.Player_Nation
    percentile_rank = round(Int, row.Percentile_Rank)  # Convert to Int

    # If the team is not already in the dictionary, add it
    if !haskey(team_dict_bowl, team)
        team_dict_bowl[team] = [0, 0]
    end

    # Increment the number of players from the team
    team_dict_bowl[team][1] += 1

    # Add the percentile rank of the player to the cumulative sum
    team_dict_bowl[team][2] += percentile_rank
end

# Add Netherlands if not already in the dictionary
if !haskey(team_dict_bowl, "Netherlands")
    team_dict_bowl["Netherlands"] = [1, 125]
else
    team_dict_bowl["Netherlands"][1] += 1
    team_dict_bowl["Netherlands"][2] += 125
end

# Define the dictionary to store the team scores
team_scores_bowl = Dict{String, Float64}()

# Iterate over the DataFrame and calculate the score for each team
for row in eachrow(df_filtered_bowl)
    team = row.Player_Nation
    percentile_rank = row.Percentile_Rank

    # If the team is not already in the dictionary, add it.
    if !haskey(team_scores, team)
        team_scores_bowl[team] = 0.0
    end

    # Add the percentile rank of the player to the team score.
    team_scores_bowl[team] += percentile_rank

    # Get the number of players from the team in the DataFrame.
    num_players = sum(df_filtered_bowl.Player_Nation .== team)

    # If there are less than 7 players from the team in the DataFrame, calculate the score for missing players.
    if num_players < 7
        # Get the lowest score of players from that team.
        lowest_score = minimum(df_filtered_bowl[df_filtered_bowl.Player_Nation .== team, :Percentile_Rank])

        # Calculate the score for the missing players.
        missing_player_score = (lowest_score / 3.0) * (7 - num_players)

        # Add the score for the missing players to the team score.
        team_scores_bowl[team] += missing_player_score
    end
end

bowling_score = Float64[]

# Print the results and store them in the 'bowling_score' array
for (team, score) in team_scores_bowl
    println("$team : $score")
    push!(bowling_score, score)
end

bowling_score = Float64[]

println(bowling_score)
# Print the results and store them in the 'bowling_score' array
for (team, score) in team_scores
    println("$team : $score")
    push!(bowling_score, score)
end
insert!(bowling_score, 6, 125.0)

# Sort the team_scores dictionary by values in descending order
sorted_team_scores = sort(collect(team_scores), by=x->x[2], rev=true)

# Print the results
for (team, score) in sorted_team_scores
    println("$team : $score")
end

print(teams)

# Define a vector to store the total scores
total_score = Float64[]

# Calculate the total scores and print them
for i in 1:length(teams)
    push!(total_score, batting_score[i] + bowling_score[i])
    println(teams[i], " : ", total_score[i])
end

# Assign the total scores to 'full_score'
full_score = total_score

total_score = copy(full_score)  

past_winners = Set(["India", "Pakistan", "Australia", "England", "Sri Lanka"])
new_countries = Set(["Afghanistan", "Netherlands"])

for (i, team) in enumerate(teams)
    if team in past_winners
        total_score[i] *= 1.2
    end

    if team in new_countries
        total_score[i] *= 0.8
    end
end
#Probability of teams winning past world cups to win this world cup is more than that of the inexperienced teams

# Print the updated total_score
println(total_score)

for i in 1:length(teams)
    println(teams[i], " ", total_score[i])
end

team_scores = copy(total_score)

points = Float64[]

for i in 1:length(teams)
    s = 0.0
    for j in 1:length(teams)
        if teams[i] != teams[j]
            s += 2 * total_score[i] / (total_score[i] + total_score[j])
        end
    end
    push!(points, s)
end

#Usecase-1 : Comparing winning probabilities for all the head to head matches in a round robin format
for i in 1:length(teams)
    for j in (i + 1):length(teams)
        prob_factor = total_score[i] + total_score[j]
        println("Match up $(teams[i]) vs $(teams[j]):")
        println("Chances to win for Team $(teams[i]): $(total_score[i] / prob_factor)")
        println("Chances to win for Team $(teams[j]): $(total_score[j] / prob_factor)")
    end
end

# Create a DataFrame
points_table = DataFrame(Team = teams, Probable_Points = points)

# Display the DataFrame
points_table

# Sort the DataFrame by 'Probable_Points' in descending order
#Use case-2: Predicting the final points table after each team plays 9matches(every other team in the competition)
sorted_result = sort(points_table, :Probable_Points, rev=true)

# Extract the top 4 teams and their points
top4_teams = sorted_result[1:4, :Team]
top4_points = sorted_result[1:4, :Probable_Points]


top4_teams = collect(top4_teams)
top4_points = collect(top4_points)

#Usecase-3: Top 4 teams/Semifinalists for the competition
top4_points = top4_points[1:4]
top4_teams = top4_teams[1:4]


#Usecase-4: Predicting the final winner of ICC Cricket World Cup 2023
for i in 1:length(top4_teams)
    chance = top4_points[i] / sum(top4_points)
    println("Chance for $(top4_teams[i]) to win World Cup 2023: $chance")
end
