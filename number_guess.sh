#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# ----------------- Funciones ---------------------
# Verifica si el nombre tiene 22 caracteres
VERIFY_NAME(){
  echo Enter your username:
  read NAME_IN
	COUNT_CHARACTERS_NAME_IN=$(echo $NAME_IN | wc -c)
	                              # -gt (mayor que)
	while [[ $COUNT_CHARACTERS_NAME_IN -gt 23 ]]
	do
		echo 'Enter your username (max 22 characters):'
		read NAME_IN
		COUNT_CHARACTERS_NAME_IN=$(echo $NAME_IN | wc -c)
	done
}

# Verificar si es un numero
VERIFY_NUMBER(){
	while [[ ! $NUMBER_IN =~ ^[0-9]+$ ]]
	do
		echo -e "\nThat is not an integer, guess again:"
		read NUMBER_IN
	done
}

NUMBER_GUESS(){
	SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))	
	# Impresion util para comprobar funcionamiento.
	#echo Secret: $SECRET_NUMBER
	echo "Guess the secret number between 1 and 1000:"
	read NUMBER_IN
	VERIFY_NUMBER
	# Variable para contar intentos.
	COUNT_GUESS=1
	# Estructura de adivinanzas de números
					# -ne (no igual)
	while [[ $SECRET_NUMBER -ne $NUMBER_IN ]]
	do
		# -gt (mayor que)	-lt (menor que)
		if [[ $NUMBER_IN -gt $SECRET_NUMBER ]]
		then
			echo -e "\nIt's lower than that, guess again:"
			read NUMBER_IN
			VERIFY_NUMBER
			COUNT_GUESS=$(expr $COUNT_GUESS + 1)
		else
			echo -e "\nIt's higher than that, guess again:"
			read NUMBER_IN
			VERIFY_NUMBER
			COUNT_GUESS=$(expr $COUNT_GUESS + 1)
		fi
	done
}

# ---------------- Ejecucion ----------------------

VERIFY_NAME

# Consulto si el nombre pertenece a la base de datos users.
IS_USER=$($PSQL "SELECT name FROM users WHERE name = '$NAME_IN'")
# si NO pertenece a la base de datos, IS_USER es vacio. 
if [[ -z $IS_USER ]]
then
	# si es vacio, es un nuevo usuario por ende hay que agregarlo a la base de datos.
	NEW_USERS=$($PSQL "INSERT INTO users (name) VALUES ('$NAME_IN')")
  NEW_USERS_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$NAME_IN'")
	echo -e "\nWelcome, $NAME_IN! It looks like this is your first time here."
	NUMBER_GUESS
	# Inserta datos en tabla game
	INSERT_GAME=$($PSQL "INSERT INTO games (user_id, tries) VALUES ($NEW_USERS_ID, $COUNT_GUESS)")
else
	USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$IS_USER'")
	GAMES_PLAYED=$($PSQL "SELECT COUNT(user_id) FROM games WHERE user_id = $USER_ID")
	BEST_GAME=$($PSQL "SELECT MIN(tries) FROM games WHERE user_id = $USER_ID")
	echo -e "\nWelcome back, $IS_USER! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."	
	NUMBER_GUESS
	# Inserta datos en tabla game
	INSERT_GAME=$($PSQL "INSERT INTO games (user_id, tries) VALUES ($USER_ID, $COUNT_GUESS)")
fi

echo -e "\nYou guessed it in $COUNT_GUESS tries. The secret number was $SECRET_NUMBER. Nice job!"