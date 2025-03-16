#!/bin/bash

# Connect to the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Ask for username
echo "Enter your username:"
read USERNAME

# Check if user exists
USER_DATA=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_DATA ]]; then
  # New user case
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)"
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
  GAMES_PLAYED=0
  BEST_GAME="None"
else
  # Existing user case: Extract user data correctly
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_DATA"

  # Ensure BEST_GAME is displayed correctly
  if [[ -z $BEST_GAME ]]; then
    BEST_GAME="None"
  fi

  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate secret number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Start game
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

while true; do
  read GUESS

  # Validate input
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Increment guess count
  ((NUMBER_OF_GUESSES++))

  # Check guess
  if [[ $GUESS -eq $SECRET_NUMBER ]]; then
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Update user stats
    ((GAMES_PLAYED++))
    $PSQL "UPDATE users SET games_played=$GAMES_PLAYED WHERE user_id=$USER_ID"

    # Update best_game if it's a new record
    if [[ $BEST_GAME == "None" || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
      $PSQL "UPDATE users SET best_game=$NUMBER_OF_GUESSES WHERE user_id=$USER_ID"
    fi

    # Exit loop after winning
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done
