#!/bin/bash

##
# This program will send an email to remind a person to do a task such as take out the garbage on a rotating basis.
# You have to do your own CRON stuff for now.
# @todo a lot of stuff. Maybe I'll make it nicer, maybe not.
# @requires sqlite3
# @requires sendmail
# @author Wil Wade <wil@wilwade.com>
#

#Config what to send!
FROMNAME="Trash Duty"
FROMEMAIL="Trash@doit.com"
SUBJECT="Your Turn for Trash!"
MESSAGE=$( cat <<EOM
Hello!
Today is your day to do the trash! If you cannot do it you must watch this video (without skipping) http://www.youtube.com/watch?v=jI-kpVh6e1U and ask someone else, but you need to make sure it happens.

Thanks!
EOM)

# Make sure that the requirements are there.
REQUIREMENTS="sqlite3 sendmail"

for r in $REQUIREMENTS
do
  if [ -z $( type -P $r ) ]
  then
    echo "Missing: "$r
    exit 1
  fi
done

sqlite3 db.db "CREATE TABLE IF NOT EXISTS people (id INTEGER PRIMARY KEY, name TEXT, email TEXT, run INTEGER DEFAULT 0);"

# Add User
if [[ $1 == add ]]
then
  echo -n "Name: "
  read NAME
  echo -n "Email: "
  read EMAIL

  if [[ -z $NAME ]]
  then
    echo "Name is required."
    exit 1
  elif [[ -z $EMAIL ]]
  then
    echo "Email is required."
    exit 1
  fi
  sqlite3 db.db "INSERT INTO people (name, email) VALUES ('""$NAME""','""$EMAIL""');"
  echo "Added ""$NAME" "$EMAIL"
  exit 0
# Remove User
elif [[ $1 == rm ]]
then
  echo "People:"
  sqlite3 db.db "SELECT id,name,email FROM people;"
  echo -n "Number by the person you wish to remove [Enter to Cancel]: "
  read RMID
  if [[ ! $RMID != *[!0-9]* ]]
  then
    echo "$RMID" "is not a number."
    exit 1
  elif [[ -z $RMID ]]
  then
    echo ""
    exit 0
  fi
  sqlite3 db.db "DELETE FROM people WHERE id = "$RMID";"
  exit 0
# Run!
elif [[ $1 == run ]]
then
  PERSON=$(sqlite3 db.db "SELECT id,email FROM people WHERE run = 0 ORDER BY id DESC;")
  if [[ -z $PERSON ]]
  then
    PERSON=$(sqlite3 db.db "UPDATE people SET run = 0; SELECT id,email FROM people WHERE run = 0 ORDER BY id DESC;")
  fi
  if [[ -z $PERSON ]]
  then
    echo "How do you expect to send an email to nobody?"
    exit 1
  fi
  PID=$(echo "$PERSON" | cut -f1 -d \|)
  PEMAIL=$(echo "$PERSON" | cut -f2 -d \|)
  sendmail "$PEMAIL" <<MSG
subject: $(date +"%m/%d/%y"): $SUBJECT
from: $FROMNAME <$FROMEMAIL>
$MESSAGE
MSG
  sqlite3 db.db "UPDATE people SET run = 1 WHERE id = ""$PID"";"
  exit 0
# Help (Bad Arguments)
else
  echo "Bash Script that handles sending am email on a schedule to a different user each time."
  echo "Usage for cron: "$0" run"
  echo "Adding Person: "$0" add"
  echo "Removing Person: "$0" rm"
  exit 0
fi
exit 0
